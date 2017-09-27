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

# import CVS table
CREATE TABLE addresses(gid serial NOT NULL, smid character varying, lat double precision, lng double precision);
COPY addresses from '//your_table_path/exampledata.csv' DELIMITERS ',' CSV header;
update addresses set smid = trim(smid, '"')
ALTER TABLE addresses add column geom geometry (Point, 4326);
UPDATE addresses SET geom = ST_SetSRID(ST_MakePoint(lng,lat), 4326);
ALTER TABLE addresses ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
CREATE INDEX addresses_gix ON addresses USING GIST (geom);
#import all data necessary and conver them to ESRI:102010
# import modelextent_1km to postgis
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\modelextent_1km.shp modelboundary | psql -d pmne -h localhost -U postgres
# import address to postgis
shp2pgsql -c -D -I -s  4269 C:\gis\p2017\pmnewengland\data\addresses.shp addresses | psql -d pmne -h localhost -U postgres
# import midatlanewengbg00_albers.shp (this dataset was reduce in size for better performace)
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\midatlanewengbg.shp midatlanewengbg | psql -d pmne -h localhost -U postgres
# import coast line to postgis
shp2pgsql -c -D -I -s  4269 C:\gis\p2017\pmnewengland\03_Coast/Coast.shp addresses | psql -d pmne -h localhost -U postgres
# import countway to postgis
shp2pgsql -c -D -I -s  4326 C:\gis\p2017\pmnewengland\data\countway.shp countway | psql -d pmne -h localhost -U postgres
# import RTA_Albers.shp (this dataset was reduce in size for better performace)
# make sure the shapefile does not have Z and M dimesnion enabled
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\12_25\RTA_Albers.shp rta | psql -d pmne -h localhost -U postgres
# import truckroutes (why use all US if it's just newengland)
shp2pgsql -c -D -I -s 4326 C:\gis\p2017\pmnewengland\data\truck.shp truck | psql -d pmne -h localhost -U postgres
# import  pbl2003 (why use all US if it's just newengland)
shp2pgsql -c -D -I -s 4326 C:\gis\p2017\pmnewengland\data\pbl2003.shp truck | psql -d pmne -h localhost -U postgres
# import stations
shp2pgsql -c -D -I -s 4326 C:\gis\p2017\pmnewengland\data\pbl2003.shp truck | psql -d pmne -h localhost -U postgres
# import ge10kadt
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\ge10kadt.shp ge10kadt | psql -d pmne -h localhost -U postgres
# import hmps13
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\hmps13.shp hmps13 | psql -d pmne -h localhost -U postgres

# import hmps1rd
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\hpms1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\hpsm1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres
shp2pgsql -c -D -I -s 5070 C:\gis\p2017\pmnewengland\data\hpsm1rd.shp hpms1rd | psql -d pmne -h localhost -U postgres




# convert layers coordinate system
ALTER TABLE modelboundary ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
ALTER TABLE midatlanewengbg ALTER COLUMN geom TYPE geometry(MultiPolygon,102003) USING ST_Transform(geom,102003);
ALTER TABLE coast ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);	
ALTER TABLE countway ALTER COLUMN geom TYPE geometry(Point,102010) USING ST_Transform(geom,102010);
ALTER TABLE rta ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE truck ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE pbl2003 ALTER COLUMN geom TYPE geometry(Point,102010) USING ST_Transform(geom,102010);	
ALTER TABLE stations ALTER COLUMN geom TYPE geometry(Point,102010) USING ST_Transform(geom,102010);
ALTER TABLE ge10kadt ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE hmps13 ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE hpms1rd ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE hpms2rd ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE hpms3rd ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);

## create spatial index for all tables
CREATE INDEX modelboundary_gix ON modelboundary USING GIST (geom);
CREATE INDEX step18_gix ON step18 USING GIST (geom);
CREATE INDEX hpms1rd_gix ON hpms1rd USING GIST (geom);
CREATE INDEX hpms2rd_gix ON hpms2rd USING GIST (geom);
CREATE INDEX hpms3rd_gix ON hpms3rd USING GIST (geom);

# spatial join STEP 01 -- verify that all points are within the modelextent1km
# only the points within the modelextent1km boundry will be included in step01 table
# requires specify addresses.geom and all fields
create table step01 as (SELECT smid, addresses.geom, lat, lng FROM addresses, modelextent1km WHERE ST_Within(addresses.geom, modelextent1km.geom));

# spatial join STEP 02
create table step02 as (SELECT DISTINCT ON (a.smid) a.smid, a.geom, a.lat, a.lng, bg.fips, bg.objectid, bg.pop00_sqmi
	FROM step01 a
		LEFT JOIN midatlanewengbg bg ON ST_DWithin(a.geom, bg.geom, 1000)
	ORDER BY a.smid, ST_Distance(a.geom, bg.geom));

#### STEP 03 >> Calculate the distance to the coast line
alter table step02 add column coastdis double precision;
update step02 set coastdis = sub.dist from (SELECT DISTINCT ON (step02.sm_id) ST_Distance(step02.geom, coast.geom)  as dist, step02.sm_id as sm
FROM step02, coast   
ORDER BY step02.sm_id, ST_Distance(step02.geom, coast.geom)) as sub where step02.sm_id = sub.sm;

### STEP 04 >> Calculate the distance to the countyway
alter table step02 add column countwaydis double precision;
update step02 set countwaydis = sub.dist from (SELECT DISTINCT ON (step02.sm_id) ST_Distance(step02.geom, countway.geom)  as dist, step02.sm_id as sm
FROM step02, countway   
ORDER BY step02.sm_id, ST_Distance(step02.geom, countway.geom)) as sub where step02.sm_id = sub.sm;
### export table to shapefile
pgsql2shp -f 'C:\gis\p2017\pmnewengland\data\step02.shp' -h localhost -u postgres -P postgres pmne "select * from step02"
### STEP06 >> extract value to point using GDAL/OGR python library >> run script raster_to_point_value.py
### make sure the script input are correct (raster path, step02 path, field name to be create)
### make sure all raster tif are projected correctly
### once this operation is completed you need to reload the step02.shp to postgis and named it step06
shp2pgsql -c -D -I -s 102010 C:\gis\p2017\pmnewengland\data\step02.shp step06 | psql -d pmne -h localhost -U postgres
### add two field and calculate values
alter table step06 add column pctdvhif12 double precision, add column pctdvlof12 double precision;

update step06 set pctdvhif12 = sub.res from (select (dvhi/144)*100 as res, step06.sm_id as sm from step06
                                            order by step06.sm_id) as sub where step06.sm_id = sub.sm ;

update step06 set pctdvlof12 = sub.res from (select (dvlo/144)*100 as res, step06.sm_id as sm from step06
                                            order by step06.sm_id) as sub where step06.sm_id = sub.sm ;                                            

### STEP 11 create two table buffer and carry all attributes
### this two step can be done later on the fly
#create table step01_50m as (select st_buffer(step01.geom, 50), * from step01)
#create table step01_100m as (select st_buffer(step01.geom, 100), * from step01)

### spatial join STEP 12 (is not clear what is the goal of this step)
### ??????????????????????????????????????
create table step10 as (SELECT DISTINCT ON (a.sm_id) a.sm_id, a.geom, rtaline.rtaid as rtaid
	FROM step06 a
		LEFT JOIN rta rtaline ON ST_DWithin(a.geom, rtaline.geom, 100000)
	ORDER BY a.sm_id, ST_Distance(a.geom, rtaline.geom)); 	
### STEP 14 Calculate Distance
alter table step06 add column dsttrkrt_m double precision;

update step06 set dsttrkrt_m = sub.dist from (SELECT DISTINCT ON (step06.sm_id) ST_Distance(step06.geom, truck.geom)  as dist, step06.sm_id as sm
FROM step06, truck   
ORDER BY step06.sm_id, ST_Distance(step06.geom, truck.geom)) as sub where step06.sm_id = sub.sm;

### STEP 13 Spatial Join with pbl2003
create table step12 as (SELECT DISTINCT ON (a.sm_id) a.sm_id, a.geom, pbl.pbl00id
	FROM step06 a
		LEFT JOIN pbl2003 pbl ON ST_DWithin(a.geom, pbl.geom, 35000)
	ORDER BY a.sm_id, ST_Distance(a.geom, pbl.geom));

### STEP 18 NEAR select the 20 nearest stations

create table step18 as(
SELECT st.geom, st.gid as step06ID, st.fips, stp.gid as stID, ST_Distance(st.geom, stp.geom) AS distance, ST_Azimuth(st.geom, stp.geom)/(2*pi())*360 as degAZ FROM
step06 AS st CROSS JOIN LATERAL
(SELECT stations.gid, stations.geom FROM stations ORDER BY st.geom <-> stations.geom LIMIT 20) AS stp  order by st.gid)

### STEP21 -- why you need to grab AADT? What's AADT?
create table step16 as (SELECT DISTINCT ON (a.sm_id) a.*, ge.aadt
	FROM step12 a
		LEFT JOIN ge10kadt ge ON ST_DWithin(a.geom, ge.geom, 10000)
	ORDER BY a.sm_id, ST_Distance(a.geom, ge.geom));

### STEP 23
create table step23 as (SELECT hmps13a.route_id, buff.sm_id, ST_Intersection(st_buffer(buff.geom, 100), hmps13a.geom)
FROM hmps13, step01 as buff WHERE ST_Intersects(st_buffer(buff.geom, 100), hmps13a.geom))

### STEP 24 - measure the distance
alter table step18 add column hpms1rd_dis double precision, add column hpms2rd_dis double precision, add column hpms3rd_dis double precision;

update step10 set  hpms1rd_dis = sub.dist from (
SELECT DISTINCT ON (step10.sm_id) ST_Distance(step10.geom, hpms1rd.geom)  as dist, step10.sm_id as sm
FROM step10, hpms1rd   
ORDER BY step10.sm_id, ST_Distance(step10.geom, hpms1rd.geom)
) as sub where step10.sm_id = sub.sm;


update step10 set  hpms2rd_dis = sub.dist from (
SELECT DISTINCT ON (step10.sm_id) ST_Distance(step10.geom, hpms2rd.geom)  as dist, step10.sm_id as sm
FROM step10, hpms2rd   
ORDER BY step10.sm_id, ST_Distance(step10.geom, hpms2rd.geom)
) as sub where step10.sm_id = sub.sm;

update step10 set  hpms3rd_dis = sub.dist from (
SELECT DISTINCT ON (step10.sm_id) ST_Distance(step10.geom, hpms3rd.geom)  as dist, step10.sm_id as sm
FROM step10, hpms3rd   
ORDER BY step10.sm_id, ST_Distance(step10.geom, hpms3rd.geom)
) as sub where step10.sm_id = sub.sm;

### STEP25 - calculate length of bus route within 50 and 100 m buffers

create table step25_50m as (SELECT rta.rtaid, buff.sm_id, ST_length(ST_Intersection(st_buffer(buff.geom, 50), rta.geom)) as len, ST_Intersection(st_buffer(buff.geom, 50), rta.geom)
FROM rta, step01 as buff WHERE ST_Intersects(st_buffer(buff.geom, 50), rta.geom))

create table step25_100m as (SELECT rta.rtaid, buff.sm_id, ST_length(ST_Intersection(st_buffer(buff.geom, 100), rta.geom)) as len, ST_Intersection(st_buffer(buff.geom, 100), rta.geom)
FROM rta, step01 as buff WHERE ST_Intersects(st_buffer(buff.geom, 100), rta.geom))
