# name: proj_shp.py -- 12/07/2017

# This script loops to all shapefile and reproject them in EPSG: 5070

# A way to run the python script is to use conda
# To install conda visit this website (https://conda.io/docs/index.html)
# Once conda is install successfully you can create a conda enviroment
# and then install gdal. If you have already installed conda and created 
# a conda project enviroment, go to step 3, otherwise follow the 
# commands below:

# 1) conda create -n pmne python=3.6
# 2) source activate pmne (this can be different if you use windows OS)
# 3) conda install -c conda-forge gdal
# 4) conda list
# 5) python /path/raster_to_point_value.py (to run the script)
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
    changeProj('/Users/cecilia/Desktop/gis/pm/newengland/data')
    