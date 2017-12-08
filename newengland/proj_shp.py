"""
ogr2ogr -f "ESRI Shapefile" /Users/cecilia/Desktop/gis/pm/newengland/data/new/g2.shp /Users/cecilia/Desktop/gis/pm/newengland/data/allregions.shp  -s_srs EPSG:102003 -t_srs EPSG:5070
"""
import os, subprocess
from osgeo import ogr, osr

# change projection for all layers in a specific folder
# the new shapefile will start with an underscore    
def changeProj(base_dir):
    for root,dirs,files in os.walk(base_dir):
        if root[len(base_dir)+1:].count(os.sep)<2:
            for file_ in files:
                #print(os.path.join(root,f))
                if file_[-3:] == 'shp':
                    shapefile_path = os.path.join(base_dir, file_)
                    # OS MAC/Linux
                    inSHP = shapefile_path
                    outSHP = base_dir + "/_" + file_
                    subprocess.call('ogr2ogr -f "ESRI Shapefile" ' + outSHP + '  ' + inSHP + ' -t_srs EPSG:5070', shell=True)
                    # OS Win
                    #inSHP = r"" + shapefile_path + ""
                    #outSHP = r"" + base_dir + "\\_" + shapefile_path.split("\\")[-1].split('.')[0] + ".shp
                    #outSHP = r"" + base_dir + "/_" + shapefile_path.split("\\")[-1].split('.')[0] + ".shp"
                    print outSHP
                    print inSHP
                    

if __name__ == '__main__':
    changeProj('/Users/cecilia/Desktop/gis/pm/newengland/data/new')
    