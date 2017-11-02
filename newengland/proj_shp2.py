"""
ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g2.shp /Users/cecilia/Desktop/gis/pm/newengland/data/allregions.shp  -s_srs EPSG:102003 -t_srs EPSG:5070
"""
import os, subprocess, ogr

os.environ['PATH'] += r'/Library/Frameworks/GDAL.framework'

# change projection for all the shapefile in a folder
def changeProj(base_dir):
    if not os.path.exists('data/new'):
        os.makedirs('data/new')
    
    full_dir = os.walk(base_dir)
    shapefile_list = []
    subprocess.call('ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g8.shp /Users/cecilia/Desktop/gis/pm/newengland/data/point.shp  -s_srs EPSG:4326 -t_srs EPSG:102003', shell=True)
           
    for source, dirs, files in full_dir:
        for file_ in files:
            if file_[-3:] == 'shp':         
                shapefile_path = os.path.join(base_dir, file_)
                #print (base_dir + "/new/" + file_[:-4] + "_proj.shp")
                #print (shapefile_path)
                #print (file_.split('.')[0] + "_proj")
                #foo(shapefile_path, base_dir + "/new/" + file_[:-4] + "_proj.shp", file_.split('.')[0] + "_proj")
        		#subprocess.call('ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g2.shp /Users/cecilia/Desktop/gis/pm/newengland/data/allregions.shp  -s_srs EPSG:102003 -t_srs EPSG:5070', shell=True)        
        break

if __name__ == '__main__':
    changeProj('/Users/cecilia/Desktop/gis/pm/newengland/data')
 