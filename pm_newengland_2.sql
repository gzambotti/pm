# spatial join STEP 01 -- verify that all points are within the modelextent1km
# only the points within the modelextent1km boundry will be included in step01 table
# requires specify addresses.geom and all fields
create table step01 as (SELECT smid, addresses.geom, lat, lng FROM addresses, modelextent1km WHERE ST_Within(addresses.geom, modelextent1km.geom));

# spatial join STEP 02 >> grab data from blockgroup dataset
create table step02 as (SELECT DISTINCT ON (a.smid) a.smid, a.geom, a.lat, a.lng, bg.fips, bg.pop_sqkm
	FROM step01 a
		LEFT JOIN midatlanewengbg bg ON ST_DWithin(a.geom, bg.geom, 1000)
	ORDER BY a.smid, ST_Distance(a.geom, bg.geom));

#### STEP 03 >> Calculate the distance to the coast line
alter table step02 add column coastdis double precision;

update step02 set coastdis = sub.dist from (SELECT DISTINCT ON (step02.smid) ST_Distance(step02.geom, coast.geom)  as dist, step02.smid as sm
FROM step02, coast   
ORDER BY step02.smid, ST_Distance(step02.geom, coast.geom)) as sub where step02.smid = sub.sm;

### STEP 04 >> Calculate the distance to the countyway
alter table step02 add column countway_m double precision;

update step02 set countway_m = sub.dist from (SELECT DISTINCT ON (step02.smid) ST_Distance(step02.geom, countway.geom)  as dist, step02.smid as sm
FROM step02, countway   
ORDER BY step02.smid, ST_Distance(step02.geom, countway.geom)) as sub where step02.smid = sub.sm;

# spatial join STEP 05 >> grab a field (modelregio) from allregions dataset
alter table step02 add column modelreg character varying;

update step02 set modelreg = sub.modelregio from (
SELECT DISTINCT ON (a.smid) a.smid, bg.modelregio
	FROM step02 a
		LEFT JOIN allregions bg ON ST_Intersects(a.geom, bg.geom)) as sub where step02.smid = sub.smid;


### export step02 postgis table to shapefile (step02.shp) -- set the output path
pgsql2shp -f "C:\\gis\\p2017\\pmnewengland\\data\\double_check\\step02.shp" -h localhost -u postgres -P postgres pmne "select * from step02"
### STEP06-10 >> extract value to point using GDAL/OGR python library >> run script raster_to_point_value.py
### make sure the script input are correct (raster path, step02 path, and the fields name to be create)
### make sure all raster tif are projected correctly (ESRI 102003)
### once this operation is completed you need to reload the step02.shp to postgis and named it step06
shp2pgsql -c -D -I -s 102003 \\path\\step02.shp step11 | psql -d pmne -h localhost -U postgres
### complete steps 06-10. Add two fields and calculate values
alter table step11 add column pctdvhif12 double precision, add column pctdvlof12 double precision;

update step11 set pctdvhif12 = sub.res from (select (dvhi_1km/144)*100 as res, step11.smid as sm from step11
                                            order by step11.smid) as sub where step11.smid = sub.smid ;

update step11 set pctdvlof12 = sub.res from (select (dvlo_cable/144)*100 as res, step11.smid as sm from step11
                                            order by step11.smid) as sub where step11.smid = sub.smid;                                            

### STEP 11 create two table buffer and carry all attributes
### this two step can be done later on the fly
#create table step01_50m as (select st_buffer(step01.geom, 50), * from step01)
#create table step01_100m as (select st_buffer(step01.geom, 100), * from step01)

### STEP 12 >> Calculate the distance to nearest RTA, and grab RTA_flag values 
alter table step11 add column rta_flag int, add column disttorta_m double precision;

update step11 set rta_flag = sub.rta_flag, disttorta_m = sub.rta_dis from (
SELECT DISTINCT ON (a.smid) a.smid, bg.rta_flag, ST_Distance(a.geom, bg.geom) as rta_dis
	FROM step11 a
		LEFT JOIN rta bg ON ST_DWithin(a.geom, bg.geom, 100000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 14 Calculate the distance to the nearest truck route
alter table step11 add column dsttrkrt_m double precision;

update step11 set dsttrkrt_m = sub.dist from (SELECT DISTINCT ON (step11.smid) ST_Distance(step11.geom, truck.geom)  as dist, step11.smid as sm
FROM step11, truck   
ORDER BY step11.smid, ST_Distance(step11.geom, truck.geom)) as sub where step11.smid = sub.sm;

### STEP 16 -- spatial join with pbl2003 >> grab a field (pblid) from pbl2003 dataset
alter table step11 add column pblid character varying;

update step11 set pblid = sub.pblid from (
SELECT DISTINCT ON (a.smid) a.smid, bg.pblid
	FROM step11 a
		LEFT JOIN pbl2003 bg ON ST_DWithin(a.geom, bg.geom, 35000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 18 -- NEAR select the 20 nearest stations
create table step18 as(
SELECT st.geom, st.smid as smid, st.lat as lat, st.lng as lng, stp.near_fid as near_fid, stp.usaf as usaf, stp.wban as wban, ST_Distance(st.geom, stp.geom) AS distance, ST_Azimuth(st.geom, stp.geom)/(2*pi())*360 as degAZ FROM
step11 AS st CROSS JOIN LATERAL
(SELECT stations.gid, stations.geom, stations.usaf, stations.wban, stations.near_fid FROM stations ORDER BY st.geom <-> stations.geom LIMIT 20) AS stp  order by st.gid)

### STEP21 -- Measure the disatance to ge10kadt, and grab AADT values
alter table step11 add column aadt double precision, add column disttoge10k double precision;

update step11 set aadt = sub.aadt, disttoge10k = sub.ge10k_dis from (
SELECT DISTINCT ON (a.smid) a.smid, bg.aadt, ST_Distance(a.geom, bg.geom) as ge10k_dis
	FROM step11 a
		LEFT JOIN ge10kadt bg ON ST_DWithin(a.geom, bg.geom, 10000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 23 >> Clip polyline within a buffer zone and sum the length of all segment within that buffer.
### The result sum will be added to the step11   
### add the column field (change the name field as you need)

alter table step11 add column hmps13_len100 double precision;

### change the query according to the buffer, and layer you need to use.

update step11 set hmps13_len100 = sub.sum from (
SELECT DISTINCT ON (buff.smid) buff.smid,  coalesce(sum(ST_Length(ST_Intersection(st_buffer(buff.geom, 100), hmps13.geom))), 0) as sum
FROM step11 as buff left join hmps13 on ST_Intersects(st_buffer(buff.geom, 100), hmps13.geom) group by buff.smid) as sub where step11.smid = sub.smid

### STEP 24 - Calculates Distance to 3 different road types
alter table step11 add column dist1rd double precision, add column dist2rd double precision, add column dist3rd double precision;

update step11 set  dist1rd = sub.dist from (
SELECT DISTINCT ON (step11.smid) ST_Distance(step11.geom, hpms1rd.geom)  as dist, step11.smid as sm
FROM step11, hpms1rd   
ORDER BY step11.smid, ST_Distance(step11.geom, hpms1rd.geom)
) as sub where step11.smid = sub.sm;


update step11 set  dist2rd = sub.dist from (
SELECT DISTINCT ON (step11.smid) ST_Distance(step11.geom, hpms2rd.geom)  as dist, step11.smid as sm
FROM step11, hpms2rd   
ORDER BY step11.smid, ST_Distance(step11.geom, hpms2rd.geom)
) as sub where step11.smid = sub.sm;

update step11 set  dist3rd = sub.dist from (
SELECT DISTINCT ON (step11.smid) ST_Distance(step11.geom, hpms3rd.geom)  as dist, step11.smid as sm
FROM step11, hpms3rd   
ORDER BY step11.smid, ST_Distance(step11.geom, hpms3rd.geom)
) as sub where step11.smid = sub.sm;

### STEP25 - calculate length of bus route within 50 and 100 m buffers
### to do it looks similar to the buffer one

create table step25_50m as (SELECT rta.rtaid, buff.sm_id, ST_length(ST_Intersection(st_buffer(buff.geom, 50), rta.geom)) as len, ST_Intersection(st_buffer(buff.geom, 50), rta.geom)
FROM rta, step01 as buff WHERE ST_Intersects(st_buffer(buff.geom, 50), rta.geom))

create table step25_100m as (SELECT rta.rtaid, buff.sm_id, ST_length(ST_Intersection(st_buffer(buff.geom, 100), rta.geom)) as len, ST_Intersection(st_buffer(buff.geom, 100), rta.geom)
FROM rta, step01 as buff WHERE ST_Intersects(st_buffer(buff.geom, 100), rta.geom))

### STEP26
alter table step11 add column disttorail double precision, add column fullname character varying;

update step11 set fullname = sub.fullname, disttorail = sub.rail_dis from (
SELECT DISTINCT ON (a.smid) a.smid, bg.fullname, ST_Distance(a.geom, bg.geom) as rail_dis
	FROM step11 a
		LEFT JOIN rail bg ON ST_DWithin(a.geom, bg.geom, 10000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 27 
alter table step11 add column disttomjrrd double precision, add column lrskey_mjrrd character varying;
## 10000 km can be too small
update step11 set lrskey_mjrrd = sub.LRSKEY, disttomjrrd = sub.mjrrd_dis from (
SELECT DISTINCT ON (a.smid) a.smid, bg.LRSKEY, ST_Distance(a.geom, bg.geom) as mjrrd_dis
	FROM step11 a
		LEFT JOIN mjrrd bg ON ST_DWithin(a.geom, bg.geom, 10000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 28 
alter table step11 add column disttombtabus double precision;
## 10000 km can be too small
update step11 disttombtabus = sub.mbtabus_dis from (
SELECT DISTINCT ON (a.smid) a.smid, ST_Distance(a.geom, bg.geom) as mbtabus_dis
	FROM step11 a
		LEFT JOIN mbtabusroutes bg ON ST_DWithin(a.geom, bg.geom, 10000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;

### STEP 29
alter table step11 add column w_area2k double precision, add column w_area10k double precision;

## buffer 2 KM
update step11 set w_area2k = sub.sum from(
SELECT DISTINCT ON (buff.smid) buff.smid,  coalesce(sum(ST_Area(ST_Intersection(st_buffer(buff.geom, 2000), water.geom))), 0) as sum
FROM step11 as buff left join water on ST_Intersects(st_buffer(buff.geom, 2000), water.geom) group by buff.smid)  as sub where step11.smid = sub.smid

## buffer 10 KM
update step11 set w_area10k = sub.sum from(
SELECT DISTINCT ON (buff.smid) buff.smid,  coalesce(sum(ST_Area(ST_Intersection(st_buffer(buff.geom, 10000), water.geom))), 0) as sum
FROM step11 as buff left join water on ST_Intersects(st_buffer(buff.geom, 10000), water.geom) group by buff.smid)  as sub where step11.smid = sub.smid

### STEP 30
alter table step11 add column latid double precision, add column lonid double precision;

update step11 set latid = sub.latid, lonid = sub.lonid from (
SELECT DISTINCT ON (a.smid) a.smid, bg.latid, bg.lonid
	FROM step11 a
		LEFT JOIN vwind bg ON ST_DWithin(a.geom, bg.geom, 35000) ORDER BY a.smid, ST_Distance(a.geom, bg.geom)) as sub where step11.smid = sub.smid ;


