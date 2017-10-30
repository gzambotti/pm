from osgeo import ogr, osr
import os

driver = ogr.GetDriverByName('ESRI Shapefile')

# get the input layer
inDataSet = driver.Open(r'/Users/cecilia/Desktop/gis/pm/newengland/v1/select.shp')
inLayer = inDataSet.GetLayer()
spatialRef = inLayer.GetSpatialRef()
print (int(spatialRef.GetAttrValue('AUTHORITY',1)))


# input SpatialReference
inSpatialRef = osr.SpatialReference()
inSpatialRef.ImportFromEPSG(int(spatialRef.GetAttrValue('AUTHORITY',1)))

# output SpatialReference
outSpatialRef = osr.SpatialReference()
outSpatialRef.ImportFromEPSG(102003)

# create the CoordinateTransformation
coordTrans = osr.CoordinateTransformation(inSpatialRef, outSpatialRef)



feature = inLayer.GetNextFeature()
geom = feature.GetGeometryRef()
print(geom.GetGeometryType())
print(geom.GetGeometryName())


if(geom.GetGeometryName() == 'POLYGON' or geom.GetGeometryName() == 'MULTIPOLYGON'):
    outTypeGeom = ogr.wkbPolygon
if(geom.GetGeometryName() == 'POINT' or geom.GetGeometryName() == 'MULTIPOINT'):
    outTypeGeom = ogr.wkbPoint
if(geom.GetGeometryName() == 'LINESTRING' or geom.GetGeometryName() == 'MULTILINESTRING'):
    outTypeGeom = ogr.wkbLineString



# create the output layer
outputShapefile = r'/Users/cecilia/Desktop/gis/pm/newengland/v1/l4.shp'
if os.path.exists(outputShapefile):
    driver.DeleteDataSource(outputShapefile)
outDataSet = driver.CreateDataSource(outputShapefile)
outLayer = outDataSet.CreateLayer("l4", geom_type=outTypeGeom)

# add fields
inLayerDefn = inLayer.GetLayerDefn()
for i in range(0, inLayerDefn.GetFieldCount()):
    fieldDefn = inLayerDefn.GetFieldDefn(i)
    outLayer.CreateField(fieldDefn)

# get the output layer's feature definition
outLayerDefn = outLayer.GetLayerDefn()

# loop through the input features
inFeature = inLayer.GetNextFeature()
while inFeature:
    # get the input geometry
    geom = inFeature.GetGeometryRef()
    # reproject the geometry
    geom.Transform(coordTrans)
    # create a new feature
    outFeature = ogr.Feature(outLayerDefn)
    # set the geometry and attribute
    outFeature.SetGeometry(geom)
    for i in range(0, outLayerDefn.GetFieldCount()):
        outFeature.SetField(outLayerDefn.GetFieldDefn(i).GetNameRef(), inFeature.GetField(i))
    # add the feature to the shapefile
    outLayer.CreateFeature(outFeature)
    # dereference the features and get the next input feature
    outFeature = None
    inFeature = inLayer.GetNextFeature()

# Save and close the shapefiles
inDataSet = None
outDataSet = None