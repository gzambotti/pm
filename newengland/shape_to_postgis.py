# name: shape_to_postgis.py -- 10/25/2017

# Before to run this script make sure that all the shapefile you would like to import are 
# within the same folder.
# Make sure to run it using conda
# To install conda visit this website (https://conda.io/docs/index.html)
# Once conda is install successfully you can create a conda enviroment
# and then install psycopg2. Below is the conda comands:

# 1) conda create -n pmne python=3.6
# 2) source activate pmne (this can be different if you use windows OS)
# 3) conda install -c conda-forge psycopg2
# 4) conda list
# 5) python /path/shape_to_postgis.py (to run the script)

# Also make sure that the name of each shapefile is the name of the table you would like to use
# later on. On a linux or Mac OS the path to shp2pgsql, psql might be different

import os, subprocess, psycopg2, ogr

# change the name of your database
db = 'pm'
# Choose your PostgreSQL version here
os.environ['PATH'] += r';C:\\Program Files\\PostgreSQL\\9.6\\bin'
# http://www.postgresql.org/docs/current/static/libpq-envars.html
os.environ['PGHOST'] = 'localhost'
os.environ['PGPORT'] = '5432'
os.environ['PGUSER'] = 'postgres'
os.environ['PGPASSWORD'] = 'postgres'
os.environ['PGDATABASE'] = db

conn = psycopg2.connect("dbname="+ db + " user=postgres password=postgres")

# output SpatialReference
outSpatialRef = osr.SpatialReference()
outSpatialRef.ImportFromEPSG(102003)


# change projection for all the shapefile in a folder
def changeProj(base_dir):
	driver = ogr.GetDriverByName('ESRI Shapefile')
	full_dir = os.walk(base_dir)
	shapefile_list = []
	for source, dirs, files in full_dir:
	    for file_ in files:
	        if file_[-3:] == 'shp':        	
	            shapefile_path = os.path.join(base_dir, file_)
	            print (shapefile_path)
	            dataset = driver.Open(shapefile_path)
	            layer = dataset.GetLayer()
	            spatialRef = layer.GetSpatialRef()
	            print (spatialRef.GetAttrValue('AUTHORITY',1))

def loadTable(base_dir):
	full_dir = os.walk(base_dir)
	shapefile_list = []
	for source, dirs, files in full_dir:
	    for file_ in files:
	        if file_[-3:] == 'shp':        	
	            shapefile_path = os.path.join(base_dir, file_)
	            #print shapefile_path
	            shapefile_list.append(shapefile_path)

	for shape_path in shapefile_list:
		shpname = shape_path.split("\\")[-1].split('.')[0]
		#print shpname
		#
		subprocess.call('shp2pgsql -c -D -I -s 5070 "' + shape_path + ' ' + shpname.lower() + '" | psql -d ' + db + ' -h localhost -U postgres ', shell=True)
		changeSRID(shpname)

def changeSRID(table):
	    cur = conn.cursor()	    
	    sql = 'select ST_GeometryType(geom) as result FROM ' + table + ' limit 1;'
	    cur.execute(sql)
	    results = cur.fetchall()
	    tablegeom = results[0][0].split("_")[1]

	    force2D(table, tablegeom)
	    #transformSRID(table, tablegeom)
	    createGeoIndex(table)

	    conn.commit()
	    cur.close

def force2D(table, tablegeom):
	cur = conn.cursor()
	sql = 'alter table ' + table + ' ALTER COLUMN geom TYPE geometry (' + tablegeom  + ') USING ST_Force2D(geom);'
	cur.execute(sql)
	cur.close

#def transformSRID(table, tablegeom):
#	cur = conn.cursor()
#	sql = 'alter table ' + table + ' ALTER COLUMN geom TYPE geometry (' + tablegeom  + ', 102003) USING ST_Transform(geom,102003);'
#	cur.execute(sql)
#	cur.close

def createGeoIndex(table):
	cur = conn.cursor()
	sql = 'create index ' + table + '_gix on ' + table + ' USING GIST (geom);'	
	cur.execute(sql)		
	cur.close
	
if __name__ == '__main__':    
	# change the name of the data path
    #loadTable('C:\\temp\\v1')
    changeProj('//Users/cecilia/Desktop/gis/pm/newengland/v1')