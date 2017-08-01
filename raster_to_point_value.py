from osgeo import gdal,ogr
import struct

def extractvalues(pathImage, pathAddresses, fieldName):
    #src_filename = r'C:/Temp/elev_clip1.tif'
    #shp_filename = r'C:/Temp/addresses1.shp'

    src_filename = pathImage
    shp_filename = pathAddresses


    src_ds=gdal.Open(src_filename) 
    gt=src_ds.GetGeoTransform()
    rb=src_ds.GetRasterBand(1)

    ds=ogr.Open(shp_filename,1)
    lyr=ds.GetLayer()
    for feat in lyr:
        geom = feat.GetGeometryRef()
        mx,my=geom.GetX(), geom.GetY()  #coord in map units

        #Convert from map to pixel coordinates.
        #Only works for geotransforms with no rotation.
        px = int((mx - gt[0]) / gt[1]) #x pixel
        py = int((my - gt[3]) / gt[5]) #y pixel
        lyr.SetFeature(feat)
        intval=rb.ReadAsArray(px,py,1,1)
        print intval[0][0] #intval is a numpy array, length=1 as we only asked for 1 pixel value
        
        feat.SetField(fieldName, float(intval[0][0]))
        lyr.SetFeature(feat)
    

if __name__ == '__main__':
    extractvalues('C:/Temp/elev_clip1.tif','C:/Temp/addresses1.shp', 'foo')