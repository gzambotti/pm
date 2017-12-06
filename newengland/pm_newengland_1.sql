-- 1) Create PostGIS database 'pmne', if you change name make sure you change the db name accordingly. 
-- 2) Make sure you fill in the 'path','username', 'passwd' with the appropriate value
----- where username is the db username, and passwd is the db password
-- 3) SRID: 4326 WGS 1984
-- 4) SRID: ESRI 102003 USA Contiguous Albers Equal Area Conic

# Make sure you have installed PostGRES/PostGIS (https://www.enterprisedb.com/)
# Create a new database and create the postgis extension
createdb pmne;
create extension postgis;

# add a new projection coordinate system to PostGRES/PostGIS (https://www.enterprisedb.com/)
# USA Contiguous Albers Equal Area Conic version (https://epsg.io/5070#)
INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 5070, 'EPSG', 5070, '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs ', 'PROJCS["NAD83 / Conus Albers",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["standard_parallel_1",29.5],PARAMETER["standard_parallel_2",45.5],PARAMETER["latitude_of_center",23],PARAMETER["longitude_of_center",-96],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["X",EAST],AXIS["Y",NORTH],AUTHORITY["EPSG","5070"]]');
# import address CVS table and create a postgis table
# make sure the CVS fields are all present into the new table
###CREATE TABLE addresses(gid serial NOT NULL, smid character varying, lat double precision, lng double precision);
###COPY addresses from '//path/exampledata.csv' DELIMITERS ',' CSV header;
# remove the double quote " character from the smid field
###update addresses set smid = trim(smid, '"')
# add the geometry field	
###ALTER TABLE addresses add column geom geometry (Point, 4326);
# fill in the coor
###UPDATE addresses SET geom = ST_SetSRID(ST_MakePoint(lng,lat), 4326);
###ALTER TABLE addresses ALTER COLUMN geom TYPE geometry(Point,102003) USING ST_Transform(geom,102003);
###CREATE INDEX addresses_gix ON addresses USING GIST (geom);
