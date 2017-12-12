-- 1) Create PostGIS database 'pmne', if you change name make sure you change the db name accordingly. 
-- 2) Make sure you fill in the 'path','username', 'passwd' with the appropriate value
----- where username is the db username, and passwd is the db password
-- 3) SRID: 4326 WGS 1984
-- 4) SRID: ESRI 5070 NAD83 / Conus Albers

# Make sure you have installed PostGRES/PostGIS (https://www.enterprisedb.com/)
# Create a new database and create the postgis extension

1) Open CMD if you are on a windows machine or a terminal if you are on a MAC or Linux
2) Connect to the deafult postgres database.
   >>> cd or dir to 'C:\Program Files\PostgreSQL\9.6\bin' 
   >>> psql -h localhost -p 5432 - U postgres
   >>> supply password
3) CREATE DATABASE database_name;
4) \c database_name;
5) create extension postgis;
6) # add a new projection coordinate system to PostGRES/PostGIS (https://www.enterprisedb.com/)
   # USA Contiguous Albers Equal Area Conic version (https://epsg.io/5070#)
   INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 5070, 'EPSG', 5070, '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=23 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs ', 'PROJCS["NAD83 / Conus Albers",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],TOWGS84[0,0,0,0,0,0,0],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],PROJECTION["Albers_Conic_Equal_Area"],PARAMETER["standard_parallel_1",29.5],PARAMETER["standard_parallel_2",45.5],PARAMETER["latitude_of_center",23],PARAMETER["longitude_of_center",-96],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["X",EAST],AXIS["Y",NORTH],AUTHORITY["EPSG","5070"]]');
