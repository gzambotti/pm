import os, subprocess, psycopg2

# Choose your PostgreSQL version here
os.environ['PATH'] += r';C:\Program Files\PostgreSQL\9.6\bin'
# http://www.postgresql.org/docs/current/static/libpq-envars.html
os.environ['PGHOST'] = 'localhost'
os.environ['PGPORT'] = '5432'
os.environ['PGUSER'] = 'postgres'
os.environ['PGPASSWORD'] = 'postgres'
os.environ['PGDATABASE'] = 'test'

conn = psycopg2.connect("dbname=test user=postgres password=postgres")

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
		print shpname
		#cmds = 'shp2pgsql -c -D -I -s 5070 "' + shape_path + '" new_shp_table | psql -d test -h localhost -U postgres '
		subprocess.call('shp2pgsql -c -D -I -s 5070 -t 2D "' + shape_path + ' ' + shpname + '" | psql -d test -h localhost -U postgres ', shell=True)
		changeSRID(shpname)

def changeSRID(table):
	    cur = conn.cursor()	    
	    sql = 'select ST_GeometryType(geom) as result FROM ' + table + ' limit 1;'
	    cur.execute(sql)
	    results = cur.fetchall()
	    print results[0][0].split("_")[1]
	    
	    sql = 'alter table ' + table + ' ALTER COLUMN geom TYPE geometry(' + results[0][0].split("_")[1]  + ',102003) USING ST_Transform(geom,102003);'
	    cur.execute(sql)
	    conn.commit()
	    cur.close

if __name__ == '__main__':    
    loadTable('C:\\gis\\p2017\\pmnewengland\\data\\v1')
    #changeSRID('allregions')    