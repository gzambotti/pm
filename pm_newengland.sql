-- Create PostGIS database 'pmne'
-- Fill in 'path','username', 'passwd' with the appropriate value
-- where username is the db username, and passwd is the db password
-- SRID: 4326 WGS 1984
-- SRID: ESI 102010 North America Equidistant Conic
-- Check the coordinate system of the shapefile to import and change
-- the shp2pgsql accordingly


createdb pmne;
create extension postgis;

# add a new projection coordinate system
# North America Equidistant Conic (https://epsg.io/102010#)
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 102010, 'ESRI', 102010, '+proj=eqdc +lat_0=40 +lon_0=-96 +lat_1=20 +lat_2=60 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ', 'PROJCS["North_America_Equidistant_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Equidistant_Conic"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Longitude_Of_Center",-96],PARAMETER["Standard_Parallel_1",20],PARAMETER["Standard_Parallel_2",60],PARAMETER["Latitude_Of_Center",40],UNIT["Meter",1],AUTHORITY["EPSG","102010"]]');

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
# import truckroutes (why all use if it's just newengland)
shp2pgsql -c -D -I -s 4326 C:\gis\p2017\pmnewengland\data\truck.shp truck | psql -d pmne -h localhost -U postgres

# convert layers coordinate system
ALTER TABLE addresses ALTER COLUMN geom TYPE geometry(Point,102010) USING ST_Transform(geom,102010);
ALTER TABLE modelboundary ALTER COLUMN geom TYPE geometry(MultiPolygon,102010) USING ST_Transform(geom,102010);
ALTER TABLE midatlanewengbg ALTER COLUMN geom TYPE geometry(MultiPolygon,102010) USING ST_Transform(geom,102010);
ALTER TABLE coast ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);	
ALTER TABLE countway ALTER COLUMN geom TYPE geometry(Point,102010) USING ST_Transform(geom,102010);
ALTER TABLE rta ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);
ALTER TABLE truck ALTER COLUMN geom TYPE geometry(MultiLineString,102010) USING ST_Transform(geom,102010);	

# spatial join STEP 01 
# requires specify addresses.geom and all fields
create table step01 as (SELECT sm_id, addresses.geom FROM addresses, area WHERE ST_Within(addresses.geom, area.geom));

# spatial join STEP 02
create table step02 as (SELECT DISTINCT ON (a.sm_id) a.sm_id, a.geom, bg.fips
	FROM step01 a
		LEFT JOIN midatlanewengbg bg ON ST_DWithin(a.geom, bg.geom, 1000)
	ORDER BY a.sm_id, ST_Distance(a.geom, bg.geom));

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
alter table step06 add column pctdvhif12 double precision;
alter table step06 add column pctdvlof12 double precision;

update step06 set pctdvhif12 = sub.res from (select (dvhi/144)*100 as res, step06.sm_id as sm from step06
                                            order by step06.sm_id) as sub where step06.sm_id = sub.sm ;

update step06 set pctdvlof12 = sub.res from (select (dvlo/144)*100 as res, step06.sm_id as sm from step06
                                            order by step06.sm_id) as sub where step06.sm_id = sub.sm ;                                            

### STEP 11 create two table buffer and carry all attributes
create table step01_50m as (select st_buffer(step01.geom, 50), * from step01)
create table step01_100m as (select st_buffer(step01.geom, 100), * from step01)

### spatial join STEP 12 (is not clear what is the goal of this step)
### ??????????????????????????????????????
create table step10 as (SELECT DISTINCT ON (a.sm_id) a.sm_id, a.geom, rtaline.rtaid as rtaid
	FROM step06 a
		LEFT JOIN rta rtaline ON ST_DWithin(a.geom, rtaline.geom, 100000)
	ORDER BY a.sm_id, ST_Distance(a.geom, rtaline.geom)); 	
### STEP 13 Calculate Distance
alter table step06 add column dsttrkrt_m double precision;

update step06 set dsttrkrt_m = sub.dist from (SELECT DISTINCT ON (step06.sm_id) ST_Distance(step06.geom, truck.geom)  as dist, step06.sm_id as sm
FROM step06, truck   
ORDER BY step06.sm_id, ST_Distance(step06.geom, truck.geom)) as sub where step06.sm_id = sub.sm;
