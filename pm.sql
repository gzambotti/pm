-- Create PostGIS database 'pm'
-- Fill in 'path','username', 'passwd' with the appropriate value
-- where username is the db username, and passwd is the db password

createdb pm
psql -d pm -c "CREATE EXTENSION postgis;"

-- Import zip code shapefile

shp2pgsql -c -D -I -s 4326 /path/OGP6995/SDE_ESRIUSZIP_POLY.shp zipcode | psql -d pm -h localhost -U username

ALTER TABLE zipcode ALTER COLUMN geom TYPE geometry(MultiPolygon,2163) USING ST_Transform(geom,2163);

-- Import census block group shapefile

shp2pgsql -c -D -I  -s 4326 /path/SDE2_ESRI07USBLKGRP.shp blockgrp | psql -d pm -h localhost -U username

ALTER TABLE blockgrp ALTER COLUMN geom TYPE geometry(MultiPolygon,2163) USING ST_Transform(geom,2163);

-- QD' PM2.5 predictions (make sure that in the csv the lng column is before the lat column
-- if this is not true, you need to change the create table statement)

create table pm25 (id oid, lat double precision, lng double precision, pm double      
precision) WITH (OIDS = FALSE);

COPY pm25 from '/path/PM25_Predictions_New_England/pm25.csv' DELIMITERS ',' CSV header;

alter table pm25 add column geom geometry (Point, 4236);

update pm25 set geom = ST_SetSRID(ST_MakePoint(lng,lat), 4236);

ALTER TABLE pm25 ALTER COLUMN geom TYPE geometry(Point, 2163) USING ST_Transform(geom, 2163);

pgsql2shp -f /path/PM25_Predictions_New_England/pm25 -h localhost -u username -P passwd pm "SELECT * FROM pm25";

drop table pm25

shp2pgsql -c -D -I  -s 2163 /path/PM25_Predictions_New_England/pm25.shp pm25 | psql -d pm -h localhost -U username


-- Import PO boxes (make sure that in the csv the lng column is before the lat column
-- if this is not true, you need to change the create table statement)

create table pobox (ID oid, zip character varying, enc_zip character varying, state character varying, area character varying, po_name character varying, nametype character varying, cty1fips character varying, cty2fips character varying, cty3fips character varying, ropo_flag character varying, zip_type character varying, lng double precision, lat double precision) WITH (OIDS=FALSE);

COPY pobox from '/path/Predicted_PM25/PO_boxes.csv' DELIMITERS ',' CSV header;

alter table pobox add column geom geometry (Point, 4236);

update pobox set geom = ST_SetSRID(ST_MakePoint(lng,lat), 4236);

ALTER TABLE pobox ALTER COLUMN geom TYPE geometry(Point, 2163) USING ST_Transform(geom, 2163);

-- Task 1: Calculate the PM average by zipcode with a buffer of 1000 (unit meters):

select zipcode.gid, sum(pm)/count(*) as averagepm, zip FROM pm25, zipcode
where ST_DWithin(zipcode.geom, pm25.geom, 1000) GROUP BY zipcode.gid;

-- Task 2: Calculate the PM average by block group, include censusid, zipcode, population, latlng fields to the table.

create table newpm25 as select sum(pm)/count(*) as averagepm, pop2007 as pop, fips, ST_Centroid(blockgrp.geom) as geom, ST_AsText(ST_Centroid(ST_Transform(blockgrp.geom, 4326))) as latlng FROM pm25, blockgrp WHERE ST_DWithin(blockgrp.geom, pm25.geom, 1000) GROUP BY blockgrp.gid;

pgsql2shp -f /path/PM25_Predictions_New_England/newpm25 -h localhost -u username -P passwd pm "SELECT * FROM newpm25";

drop table newpm25

shp2pgsql -c -D -I  -s 2163 /path/PM25_Predictions_New_England/newpm25.shp newpm25 | psql -d pm -h localhost -U username

select fips as censusid, zip, averagepm, pop, latlng from newpm25, zipcode where st_intersects(newpm25.geom, zipcode.geom);

-- Task 3: Calculate the PM average by PO BOX with a buffer of 1000 (unit meters):

select pobox.id, count(*) as totpm, sum(pm) as totsumpm, sum(pm)/count(*) as averagepm FROM pm25, pobox where ST_DWithin(pobox.geom, pm25.geom, 1000) GROUP BY pobox.id;

-- Task 4: Calculate the PM average by block group, include censusid, blockgroup population, latlng fields to the table

select fips as censusid, zip, averagepm, pop, latlng from newpm25, pobox where st_DWithin(newpm25.geom, pobox.geom, 1000) 
