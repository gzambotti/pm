# code by Giovanni Zambotti  11/1/2017
# convert a CVS file to a shapefile
# the script works with a predifine schema and projection
# if the CVS file has a different structure please make 
# sure you change the schema as well as the prj

# python requirement: shapely and fiona
# conda install -c scitools shapely
# conda install -c conda-forge fiona


import csv
from shapely.geometry import Point, mapping
from fiona import collection

# set up a schema for the shapefile
schema = { 'geometry': 'Point', 'properties': { 'unique_id': 'str' } }
# set up a prj file 
prj = {'init': u'epsg:4326'}
# change the name of the output shapefile and the CVS file
with collection("some1.shp", "w", "ESRI Shapefile", schema, prj) as output:
    with open('exampledata.csv', 'rb') as f:
        reader = csv.DictReader(f)
        for row in reader:
            point = Point(float(row['Longitude']), float(row['Latitude']))
            output.write({
                'properties': {
                    'unique_id': row['unique_id']
                },
                'geometry': mapping(point)
            })