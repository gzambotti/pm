-- Create PostGIS database 'pmne'
-- Fill in 'path','username', 'passwd' with the appropriate value
-- where username is the db username, and passwd is the db password
-- SRID: 4326 WGS 1984
-- SRID: ESRI 102010 North America Equidistant Conic
-- SRID: ESRI 102003 USA Contiguous Albers Equal Area Conic
-- Check the coordinate system of the shapefile to import and change
-- the shp2pgsql accordingly


createdb pmne;
create extension postgis;

# add a new projection coordinate system
# North America Equidistant Conic (https://epsg.io/102010#)
# INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 102010, 'ESRI', 102010, '+proj=eqdc +lat_0=40 +lon_0=-96 +lat_1=20 +lat_2=60 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ', 'PROJCS["North_America_Equidistant_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Equidistant_Conic"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Longitude_Of_Center",-96],PARAMETER["Standard_Parallel_1",20],PARAMETER["Standard_Parallel_2",60],PARAMETER["Latitude_Of_Center",40],UNIT["Meter",1],AUTHORITY["EPSG","102010"]]');

# USA Contiguous Albers Equal Area Conic version (https://epsg.io/102003#)
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 102003, 'ESRI', 102003, '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Albers_Equal_Area_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["longitude_of_center",-96],PARAMETER["Standard_Parallel_1",29.5],PARAMETER["Standard_Parallel_2",45.5],PARAMETER["latitude_of_center",37.5],UNIT["Meter",1],AUTHORITY["EPSG","102003"]]');

# import address CVS table and create a postgis table
CREATE TABLE addresses(gid serial NOT NULL, smid character varying, lat double precision, lng double precision);
COPY addresses from '//your_table_path/exampledata.csv' DELIMITERS ',' CSV header;
update addresses set smid = trim(smid, '"')
ALTER TABLE addresses add column geom geometry (Point, 4326);
UPDATE addresses SET geom = ST_SetSRID(ST_MakePoint(lng,lat), 4326);
ALTER TABLE addresses ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
CREATE INDEX addresses_gix ON addresses USING GIST (geom);

# import all data necessary and convert them to ESRI:102003
# import modelextent_1km to postgis
shp2pgsql -c -D -I -s 5070 \\path\modelextent_1km.shp modelboundary | psql -d pmne -h localhost -U postgres
# import midatlanewengbg00_albers.shp (this dataset was reduce in size for better performace)
shp2pgsql -c -D -I -s 5070 \\path\midatlanewengbg00_subset.shp midatlanewengbg | psql -d pmne -h localhost -U postgres
# import coast line to postgis
shp2pgsql -c -D -I -s  4269 \\path\Coast.shp addresses | psql -d pmne -h localhost -U postgres
# import countway to postgis
shp2pgsql -c -D -I -s  5070 \\path\countway_albers.shp countway | psql -d pmne -h localhost -U postgres
# import allregions (new england regions shapefile) to postgis
shp2pgsql -c -D -I -s  5070 \\path\allregions_albers.shp allregions | psql -d pmne -h localhost -U postgres
# import RTA_red.shp (this dataset was reduce in size for better performace)
shp2pgsql -c -D -I -s 5070 \\path\RTA_red.shp rta | psql -d pmne -h localhost -U postgres
# import truckroutes
shp2pgsql -c -D -I -s 5070 \\path\truckrtes_clip.shp truck | psql -d pmne -h localhost -U postgres
# import  pbl2003 
shp2pgsql -c -D -I -s 5070 \\path\pbl2003.shp pbl2003 | psql -d pmne -h localhost -U postgres
# import stations
shp2pgsql -c -D -I -s 5070 \\path\stations_clip.shp stations | psql -d pmne -h localhost -U postgres
# import ge10kadt
shp2pgsql -c -D -I -s 5070 \\path\ge10kadt.shp ge10kadt | psql -d pmne -h localhost -U postgres
# import hmps13
shp2pgsql -c -D -I -s 5070 \\path\hmps13.shp hmps13 | psql -d pmne -h localhost -U postgres

# import hmps1rd
shp2pgsql -c -D -I -s 5070 \\path\hpms1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres
shp2pgsql -c -D -I -s 5070 \\path\hpsm1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres
shp2pgsql -c -D -I -s 5070 \\path\hpsm1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres
# import rail
shp2pgsql -c -D -I -s 5070 \\path\Rail_red.shp rail | psql -d pmne -h localhost -U postgres
# import mjrrd
shp2pgsql -c -D -I -s 5070 \\path\mjrrd_red.shp mjrrd | psql -d pmne -h localhost -U postgres
# import mbtabusroutes
shp2pgsql -c -D -I -s 5070 \\path\mbta_red.shp mbtabusroutes | psql -d pmne -h localhost -U postgres

# import waterbodies
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\29\water_bodies.shp water | psql -d pmne -h localhost -U postgres
# import vwind
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\30\vwind_modelextent.shp vwind | psql -d pmne -h localhost -U postgres

# convert layers coordinate system to ESI 102003
ALTER TABLE modelboundary ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
ALTER TABLE midatlanewengbg ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
ALTER TABLE coast ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);	
ALTER TABLE countway ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
ALTER TABLE allregions ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
# disable Z and M dimension
# Avoid this ERROR: Geometry has Z dimension but column does not
# Avoid this ERROR: Geometry has M dimension but column does not
ALTER TABLE rta ALTER COLUMN geom TYPE geometry(MultiLineString) USING ST_Force2D(geom);
ALTER TABLE rta ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE truck ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE pbl2003 ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);	
ALTER TABLE stations ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
ALTER TABLE ge10kadt ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE hmps13 ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE hpms1rd ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE hpms2rd ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE hpms3rd ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE rail ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);

ALTER TABLE mjrrd ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
ALTER TABLE mbtabusroutes ALTER COLUMN geom TYPE geometry(MultiLineString,102003) USING ST_Transform(geom,102003);
# water bodies
ALTER TABLE water ALTER COLUMN geom TYPE geometry(MultiPolygon) USING ST_Force2D(geom);
ALTER TABLE water ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
# vwind
ALTER TABLE vwind ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
## create spatial index for all tables
CREATE INDEX modelboundary_gix ON modelboundary USING GIST (geom);
CREATE INDEX midatlanewengbg_gix ON midatlanewengbg USING GIST (geom);
CREATE INDEX coast_gix ON coast USING GIST (geom);
CREATE INDEX countway_gix ON countway USING GIST (geom);
CREATE INDEX allregions_gix ON allregions USING GIST (geom);
CREATE INDEX rta_gix ON rta USING GIST (geom);
CREATE INDEX truck_gix ON truck USING GIST (geom);
CREATE INDEX pbl2003_gix ON pbl2003 USING GIST (geom);
CREATE INDEX stations_gix ON stations USING GIST (geom);
CREATE INDEX ge10kadt_gix ON ge10kadt USING GIST (geom);
CREATE INDEX hmps13_gix ON hmps13 USING GIST (geom);
CREATE INDEX hpms1rd_gix ON hpms1rd USING GIST (geom);
CREATE INDEX hpms2rd_gix ON hpms2rd USING GIST (geom);
CREATE INDEX hpms3rd_gix ON hpms3rd USING GIST (geom);
CREATE INDEX rail_gix ON rail USING GIST (geom);
CREATE INDEX mjrrd_gix ON mjrrd USING GIST (geom);
CREATE INDEX mbtabusroutes_gix ON mbtabusroutes USING GIST (geom);
CREATE INDEX water_gix ON water USING GIST (geom);
CREATE INDEX vwind_gix ON vwind USING GIST (geom);

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
alter table step11 add column disttombtabus double precision, add column LRSKEY character varying;
## 10000 km can be too small
update step11 set LRSKEY = sub.LRSKEY, disttombtabus = sub.mbtabus_dis from (
SELECT DISTINCT ON (a.smid) a.smid, bg.LRSKEY, ST_Distance(a.geom, bg.geom) as mbtabus_dis
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


