# name: raster_to_point_value.py -- 2/15/2018

# This script extract the value from a raster file and load into a shapefile
# Make sure that raster and shapefile are project in the same coordinate system 
# For this project we use EPGS: 5070

# A way to run the python script is to use conda
# To install conda visit this website (https://conda.io/docs/index.html)
# Once conda is install successfully you can create a conda enviroment
# and then install gdal. If you have already installed conda and created 
# a conda project enviroment, go to step 3, otherwise follow the 
# commands below:

# 1) conda create -n pmne python=3.6, python 2.7 should work as well
# 2) source activate pmne (this can be different if you use windows OS)
# 3) conda install -c conda-forge gdal
# 4) conda list
# 5) python /path/raster_to_point_value.py (to run the script)

from osgeo import gdal,ogr
import struct

def extractvalues(pathImage, pathAddresses, fieldName):
    
    src_filename = pathImage
    shp_filename = pathAddresses

    src_ds=gdal.Open(src_filename) 
    gt=src_ds.GetGeoTransform()
    rb=src_ds.GetRasterBand(1)
    # reading the raster size and the raster min/max values
    rasterX = src_ds.RasterXSize
    rasterY = src_ds.RasterYSize
    rasterMin = rb.GetMinimum()
    rasterMax = rb.GetMaximum()
    #print (rasterMin, rasterMax)
    # in order to write to a shapefile we need to add 1
    ds=ogr.Open(shp_filename,1)
    lyr=ds.GetLayer()    
    # create a new field >> ogr.OFTReal (Double Precision floating point)
    lyr.CreateField(ogr.FieldDefn(fieldName, ogr.OFTReal))
    for feat in lyr:
        try:
            geom = feat.GetGeometryRef()
            mx,my=geom.GetX(), geom.GetY()  #coord in map units
            #Convert from map to pixel coordinates.
            #Only works for geotransforms with no rotation.
            px = int((mx - gt[0]) / gt[1]) #x pixel
            py = int((my - gt[3]) / gt[5]) #y pixel
            lyr.SetFeature(feat)
            intval=rb.ReadAsArray(px,py,1,1)
            if((px < 0 or px > rasterX) or (py < 0 or py > rasterY)):
                #print (-999, -999)
                feat.SetField(fieldName, float(-9999))
                lyr.SetFeature(feat)
            else:    
                #print (px, py)
                #print (intval[0][0]) #intval is a numpy array, length=1 as we only asked for 1 pixel value
                if(intval[0][0] >= rasterMin and intval[0][0] <= rasterMax):
                    feat.SetField(fieldName, float(intval[0][0]))
                    lyr.SetFeature(feat)
                else:
                    feat.SetField(fieldName, float(-9999))
                    lyr.SetFeature(feat)

        except Exception as e:
            print(e)
            
    

if __name__ == '__main__':
    # extract elevation
    extractvalues(r'\\path\\elev', r'\\data\\new\\addresses.shp', 'elev_m')
    # STEP 07-08 >> extract dvhi_1km values -- uncomment next line
    extractvalues(r'\\path\\dvhi_1kmus', r'\\data\\new\\addresses.shp', 'dvhi_1km')
    # STEP 09 >> extract dvlo_1km values -- uncomment next line
    extractvalues(r'\\path\\dvlo_1kmus', r'\\data\\new\\addresses.shp', 'dvlo_cable')
    # STEP 10 >> extract imp_1km values  -- uncomment next line
    extractvalues(r'\\path\\imp_1kmus', r'\\data\\new\\addresses.shp', 'pctimpfs_1')