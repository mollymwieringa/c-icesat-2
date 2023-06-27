#### Description ####
# This script links ERA5 data to raw data directory. The ERA5 data is stored in the following directory structure:
# /projects/c-icesat-2/data/raw/ERA5/era5_{var}/{year}/{month}/era5_{var}_{year}{month}{day}.nc
#### Usage ####
# where {var} is the variable name, {year} is the year, {month} is the month, and {day} is the day.
# The script will symbolically link the data from the NCAR RDA to the following directory structure:   
# /projects/c-icesat-2/data/raw/ERA5/era5_{var}/{year}/{month}/era5_{var}_{year}{month}{day}.nc
#### Author(s) ####
# Name: Molly Wieringa
# Institution: University of Washington
# Department: Atmospheric Sciences
# Date Created: 2023-06-20
# Date Modified: 2021-06-20
#### Notes ####
# 1. Going to have to convert q and t to 10 meter from the pl files 
# 2. Going to have to process the total precip from large scale precipitation (LSP) and convective precipitation (CP)
# 3. The 10m U,V are readily available in the surface files, so that's fun 
# 4. Radiation fields are ssrd and strd, based on ERA5Interim examples from Francois Massonnet
#### User Input ####
# The user must specify the following:
# 1. The variable name {var} (e.g., '2t' for 2m temperature)
# 2. The start year {start_year} (e.g., 1979)
# 3. The end year {end_year} (e.g., 2020)
# 4. The start month {start_month} (e.g., 1)
# 5. The end month {end_month} (e.g., 12)

#### Import modules ####
import os
import glob
import numpy as np
import xarray as xr
import sys

# variable list = [t2m, 10t, q2m, 10q, 10u, 10v, qlw, qsw, precip]
var = sys.argv[1] #'t2m'
start_year = int(sys.argv[2]) #2000
end_year = int(sys.argv[3]) #2023
start_month = 1
end_month = 12  

rda_file_path = '/glade/collections/rda/data/ds633.0/'

# For each variable requested, find all the required variables and link them into a subdirectory in the raw/ERA5 directory

for year in range(start_year, end_year + 1):
    for month in range(start_month, end_month + 1):
        if var == 'q':
            files  = sorted(glob.glob(rda_file_path + 'e5.oper.an.pl/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.pl.128_133_q.ll025sc.*.nc'))
        elif var == 't':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.an.pl/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.pl.128_130_t.ll025sc.*.nc'))
        elif var == '10u':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.an.sfc/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.sfc.128_165_10u.ll025sc.*.nc'))
        elif var == '10v':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.an.sfc/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.sfc.128_166_10v.ll025sc.*.nc'))
        elif var == 'ssrd':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.fc.sfc.accumu/'+str(year)+"{:02d}".format(month)+'/e5.oper.fc.sfc.accumu.128_169_ssrd.ll025sc.*.nc'))
        elif var == 'strd':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.fc.sfc.accumu/'+str(year)+"{:02d}".format(month)+'/e5.oper.fc.sfc.accumu.128_175_strd.ll025sc.*.nc'))
        elif var == 'precip':
            # for precip, we need to link both the large scale precipitation (LSP) and convective precipitation (CP) files
            files1 = sorted(glob.glob(rda_file_path + 'e5.oper.fc.sfc.accumu/'+str(year)+"{:02d}".format(month)+'/e5.oper.fc.sfc.accumu.128_142_lsp.ll025sc.*.nc'))
            files2 = sorted(glob.glob(rda_file_path + 'e5.oper.fc.sfc.accumu/'+str(year)+"{:02d}".format(month)+'/e5.oper.fc.sfc.accumu.128_143_cp.ll025sc.*.nc'))
            files = files1 + files2
        elif var == 'sp':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.an.sfc/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.sfc.128_134_sp.ll025sc.*.nc'))
        elif var == 'slp':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.an.sfc/'+str(year)+"{:02d}".format(month)+'/e5.oper.an.sfc.128_151_msl.ll025sc.*.nc'))
        elif var == 'runoff':
            files = sorted(glob.glob(rda_file_path + 'e5.oper.fc.sfc.accumu/'+str(year)+"{:02d}".format(month)+'/e5.oper.fc.sfc.accumu.128_205_ro.ll025sc.*.nc'))
        else:
            print('Variable not found')
            sys.exit()
 
        os.makedirs('../raw/ERA5/'+var+'/'+str(year)+'/'+"{:02d}".format(month), exist_ok=True)
        # Check that the file list is not empty
        if not files:
            print('No files found for '+str(year)+'/'+"{:02d}".format(month))
            continue
        else:
            print('Linking '+str(len(files))+' files for '+str(year)+'/'+"{:02d}".format(month))
            # Link the files into the directory
            for file in files:
                os.symlink(file, '../raw/ERA5/'+var+'/'+str(year)+'/'+"{:02d}".format(month)+'/'+os.path.basename(file))
        
    # signal that the year is done
    print('Done with '+str(year))

# signal that the script is done
print('Done with '+var)


        