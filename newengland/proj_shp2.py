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
    inSHP = r'C:\gis\p2017\pm\pm\newengland\data\all.shp'
    outSHP = r'C:\gis\p2017\pm\pm\newengland\data\pall.shp'
    subprocess.call('ogr2ogr -f "ESRI Shapefile" ' + outSHP + '  ' + inSHP + ' -t_srs EPSG:5070', shell=True)

    
def listShapefile(base_dir):
    for root,dirs,files in os.walk(base_dir):
        if root[len(base_dir)+1:].count(os.sep)<2:
            for file_ in files:
                #print(os.path.join(root,f))
                if file_[-3:] == 'shp':
                    shapefile_path = os.path.join(base_dir, file_)
                    inSHP = r"" + shapefile_path + ""
                    #outSHP = r"'" + shapefile_path + "'"
                    outSHP = r"" + base_dir + "\\_" + shapefile_path.split("\\")[-1].split('.')[0] + ".shp"
                    subprocess.call('ogr2ogr -f "ESRI Shapefile" ' + outSHP + '  ' + inSHP + ' -t_srs EPSG:5070', shell=True)
                    print outSHP
                    print inSHP
                    

if __name__ == '__main__':
    #changeProj(r'C:\\gis\\p2017\\pm\\pm\\newengland\\data')
    listShapefile(r'C:\gis\p2017\pm\pm\newengland\data\new')