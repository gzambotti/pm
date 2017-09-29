# A way to run the python script is to use conda
# To install conda visit this website (https://conda.io/docs/index.html)
# Once conda is install successfully you can create a conda enviroment
# and then install gdal. Below is the conda comands:

# 1) conda create -n pmne python=3.6
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
    # in order to write to a shapefile we need to add 1
    ds=ogr.Open(shp_filename,1)
    lyr=ds.GetLayer()    
    # create a new field >> ogr.OFTReal (Double Precision floating point)
    lyr.CreateField(ogr.FieldDefn(fieldName, ogr.OFTReal))
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
    # extract elevation
    extractvalues(r'\\path\\elev_clipUS.tif', r'\\path\\step02.shp', 'elev_m')
    # STEP 07-08 >> extract dvhi_1km values
    extractvalues(r'\\path\\dvhi_1kmus', r'\\path\\step02.shp', 'dvhi_1km')
    # STEP 09 >> extract dvlo_1km values
    extractvalues(r'\\path\\dvlo_1kmus', r'\\path\\step02.shp', 'dvlo_cable')
    # STEP 10 >> extract imp_1km values
    extractvalues(r'\\path\\imp_1kmus', r'\\path\\step02.shp', 'pctimpfs_1')