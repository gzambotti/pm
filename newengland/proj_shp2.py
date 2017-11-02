"""
ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g2.shp /Users/cecilia/Desktop/gis/pm/newengland/data/allregions.shp  -s_srs EPSG:102003 -t_srs EPSG:5070
"""
import os, subprocess
from osgeo import ogr, osr
driver = ogr.GetDriverByName('ESRI Shapefile')
#os.environ['PATH'] += r'C:\\Program Files\\QGIS 2.18\\bin'
#C:\Program Files\QGIS 2.18\bin --- /Library/Frameworks/GDAL.framework
# change projection for all the shapefile in a folder
def changeProj(base_dir):
    if not os.path.exists('data/new'):
        os.makedirs('data/new')
    
    full_dir = os.walk(base_dir)
    shapefile_list = []
    #subprocess.call('ogr2ogr.exe -f "ESRI Shapefile" C:\gis\p2017\pm\pm\\newengland\data\\new\g1.shp C:\gis\p2017\pm\pm\\newengland\data\\bg.shp -s_srs EPSG:5070 -t_srs EPSG:102003', shell=True)
           
    for source, dirs, files in full_dir:
        for file_ in files:
            if file_[-3:] == 'shp':         
                shapefile_path = os.path.join(base_dir, file_)
                #print (base_dir + "/new/" + file_[:-4] + "_proj.shp")
                inFile = base_dir + "\\" + file_
                outFile =  base_dir + "\\new\\" + file_.split('.')[0] + "_proj.shp"
                inDataSet = driver.Open("C:\\gis\\p2017\\pm\\pm\\newengland\\data\bg.shp")
                inLayer = inDataSet.GetLayer()
                spatialRef = inLayer.GetSpatialRef()
                print (spatialRef.GetAttrValue('AUTHORITY',1))
                print (inFile)
                print (outFile)
                #foo(shapefile_path, base_dir + "/new/" + file_[:-4] + "_proj.shp", file_.split('.')[0] + "_proj")
        		#subprocess.call('ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g2.shp /Users/cecilia/Desktop/gis/pm/newengland/data/allregions.shp  -s_srs EPSG:102003 -t_srs EPSG:5070', shell=True)        
        break

if __name__ == '__main__':
    changeProj(r'C:\\gis\\p2017\\pm\\pm\\newengland\\data')
 