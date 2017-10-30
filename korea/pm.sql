-- Create PostGIS database 'pm'
-- Fill in 'path','username', 'passwd' with the appropriate value
-- where username is the db username, and passwd is the db password
-- SRID: 4326 WGS 1984
-- SRID: 2163 US National Atlas Equal Area
-- Check the coordinate system of the shapefile to import and change
-- the shp2pgsql accordingly

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

CREATE TABLE pm25 (gid serial NOT NULL, lat double precision, lng double precision, pm double precision);

COPY pm25 from '/path/PM25_Predictions_New_England/pm25.csv' DELIMITERS ',' CSV header;

ALTER TABLE pm25 add column geom geometry (Point, 4326);

UPDATE pm25 SET geom = ST_SetSRID(ST_MakePoint(lng,lat), 4326);

ALTER TABLE pm25 ALTER COLUMN geom TYPE geometry(Point, 2163) USING ST_Transform(geom, 2163);

--ALTER TABLE pm25 add CONSTRAINT pm25_pkey PRIMARY KEY (gid)

CREATE INDEX pm25_gix ON pm25 USING GIST (geom);

-- Import PO boxes (make sure that in the csv the lng column is before the lat column
-- if this is not true, you need to change the create table statement)

CREATE TABLE pobox (gid serial NOT NULL, zip character varying, enc_zip character varying, state character varying, area character varying, po_name character varying, nametype character varying, cty1fips character varying, cty2fips character varying, cty3fips character varying, ropo_flag character varying, zip_type character varying, lng double precision, lat double precision);

COPY pobox from '/path/Predicted_PM25/PO_boxes.csv' DELIMITERS ',' CSV header;

ALTER TABLE pobox add column geom geometry (Point, 4326);

UPDATE pobox SET geom = ST_SetSRID(ST_MakePoint(lng,lat), 4326);

ALTER TABLE pobox ALTER COLUMN geom TYPE geometry(Point, 2163) USING ST_Transform(geom, 2163);

--ALTER TABLE pobox add CONSTRAINT pobox_pkey PRIMARY KEY (gid)

CREATE INDEX pobox_gix ON pobox USING GIST (geom);

-- Task 1: Calculate the PM average by zipcode with a buffer of 1000 (unit meters):

SELECT zipcode.gid, sum(pm)/count(*) AS averagepm, zip FROM pm25, zipcode
WHERE ST_DWithin(zipcode.geom, pm25.geom, 1000) GROUP BY zipcode.gid;

-- Task 2: Calculate the PM average by block group, include censusid, zipcode, population, latlng fields to the table.

CREATE TABLE newpm25 AS SELECT sum(pm)/count(*) AS averagepm, pop2007 AS pop, fips, ST_Centroid(blockgrp.geom) AS geom, ST_AsText(ST_Centroid(ST_Transform(blockgrp.geom, 4326))) AS latlng FROM pm25, blockgrp WHERE ST_DWithin(blockgrp.geom, pm25.geom, 1000) GROUP BY blockgrp.gid;

CREATE INDEX newpm25_gix ON newpm25 USING GIST (geom);

SELECT fips AS censusid, zip, averagepm, pop, latlng FROM newpm25, zipcode WHERE st_intersects(newpm25.geom, zipcode.geom);

-- Task 3: Calculate the PM average by PO BOX with a buffer of 1000 (unit meters):

SELECT pobox.gid, count(*) AS totpm, sum(pm) AS totsumpm, sum(pm)/count(*) AS averagepm FROM pm25, pobox WHERE ST_DWithin(pobox.geom, pm25.geom, 1000) GROUP BY pobox.gid;

-- Task 4: Calculate the PM average by block group, include censusid, blockgroup population, latlng fields to the table

SELECT fips AS censusid, zip, averagepm, pop, latlng FROM newpm25, pobox WHERE st_DWithin(newpm25.geom, pobox.geom, 1000) 
