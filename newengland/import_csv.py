# code by Giovanni Zambotti  12/4/2017
# convert a CVS file to a shapefile
# the script works with a predifine schema and projection
# if the CVS file has a different structure please make 
# sure you change the schema as well as the prj

# python requirement: shapely and fiona
# conda install -c scitools shapely
# conda install -c conda-forge fiona


import csv, os, subprocess
from shapely.geometry import Point, mapping
from fiona import collection
from osgeo import ogr, osr

"""
convert CSV file to shapefile
"""
def importCSVFile(csvPath, shpPath):
    # set up a schema for the shapefile
    schema = { 'geometry': 'Point', 'properties': { 'unique_id': 'str' } }
    # set up a prj file 
    prj = {'init': u'epsg:4326'}
    # change the name of the output shapefile and the CVS file
    with collection(shpPath, "w", "ESRI Shapefile", schema, prj) as output:
        with open(csvPath, 'rb') as f:
            reader = csv.DictReader(f)
            for row in reader:
                point = Point(float(row['Longitude']), float(row['Latitude']))
                output.write({
                    'properties': {
                        'unique_id': row['unique_id']
                    },
                    'geometry': mapping(point)
                })

"""
change the shapefile projection from 4326 to 5070 using ogr2ogr
"""
def changeProj(inSHP, outSHP):
    #if not os.path.exists('data/new'):
    #    os.makedirs('data/new')
    
    #full_dir = os.walk(base_dir)
    #shapefile_list = []
    subprocess.call('ogr2ogr -f "ESRI Shapefile" ' + outSHP + '  ' + inSHP + ' -s_srs EPSG:4326 -t_srs EPSG:5070', shell=True)


if __name__ == '__main__':
    importCSVFile(r'C:\gis\p2017\pm\pm\newengland\data\exampledata.csv',r'C:\gis\p2017\pm\pm\newengland\data\z2.shp')
    changeProj(r'C:\gis\p2017\pm\pm\newengland\data\z2.shp', r'C:\gis\p2017\pm\pm\newengland\data\new\addresses.shp')