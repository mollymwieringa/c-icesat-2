#-------------------------------- Description --------------------------------#
# This script links the single member JRA55 forcing data to raw data directory. 
# The JRA55 data is stored in the following directory structure:
# /projects/c-icesat-2/data/raw/JRA55/{var}/JRA.v1.5.{var}.TL319.{year}.*.nc'
# where {var} is the variable name and {year} is the year.
#---------------------------------- Usage ------------------------------------#
# The script will symbolically link the data from the NCAR DATM forcing repos-
# -tory to the above directory structure. The user must specify the following:
# 1. The variable name {var} (e.g., '2t' for 2m temperature)
# 2. The start year {start_year} (e.g., 1979)
# 3. The end year {end_year} (e.g., 2020)
#--------------------------------- Author(s) ---------------------------------#
# Name: Molly Wieringa
# Institution: University of Washington
# Department: Atmospheric Sciences
# Date Created: 2023-06-22  
# Date Modified: 2021-06-22
#----------------------------------- Notes -----------------------------------#

#-------------------------------- Import Modules -----------------------------#
import os
import glob
import sys
#-------------------------------- User Input ---------------------------------#
var = sys.argv[1] #'t2m'
start_year = int(sys.argv[2]) #2000
end_year = int(sys.argv[3]) #2023

forcing_file_path = '/glade/p/cesmdata/cseg/inputdata/ocn/jra55/v1.5_noleap/'
#--------------------------------- Find Files --------------------------------#
# If necesssary, create the raw/JRA55 directory
if not os.path.exists('../../raw/JRA55/'):
    os.makedirs('../../raw/JRA55/')

# For each variable requested, find all the required variables and link them
for year in range(start_year, end_year + 1):
    files = sorted(glob.glob(forcing_file_path + '/JRA.v1.5.'+var+'*'+str(year)+'.*.nc'))
    # Check that files is not empty
    if files:
        # If necessary, create the raw/JRA55/{var} directory
        if not os.path.exists('../../raw/JRA55/'+var+'/'):
            os.makedirs('../../raw/JRA55/'+var+'/')
        # Link the files
        for file in files:
            os.symlink(file, '../../raw/JRA55/'+var+'/'+os.path.basename(file))
        # Progress report
        print('Linked '+str(len(files))+' files for '+var+' in '+str(year))
    else:
        print('No files found for '+var+' in '+str(year))

#--------------------------------- End Script --------------------------------#
