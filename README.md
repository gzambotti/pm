# Particulate matter project pm 2.5
  - Requirements: 
    - Conda (https://conda.io/docs/index.html)
  	- PostGRES/PostGIS (https://www.enterprisedb.com/)
  	- All the scripts are set to run on a Windows OS, if you are planning to run them on a different OS
  	  make sure that all the data and software path are correct.
  	- Create a folder that holds all the shapefile dataset.
  	- The shapefile dataset must be projected in the   

# PM New England
0. **import_csv.py**
	- Covert a csv file to shapefile (addresses.shp), and store it in the same shapefiel folder.
	- Change projection to the shapefile using ogr2ogr command line.

1. **raster_to_point_value.py**
	- import the raster values to the shapefile address

2. **pm_newengland_1.sql**
	- Create a new DB, and PostGIS extension.
	- Add the coordinate system required [NAD83 / Conus Albers (https://epsg.io/5070#)].

3. **shape_to_postgis.py**
	- Import all the shapefile to PostGIS:
		- Make sure all the shapefile are stored in the same folder.
		- The name of the shapefile will be the name of the table, rename them if need it.
		- Make sure they all have the same coordinate system, by default should be (NAD83 / Conus Albers).
		- Create a spatial index for all tables.

4. **pm_newengland_2.sql**
	- Run all sql statement	




