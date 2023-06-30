# ============================ Introduction ===============================
# This script is used to create the perturbations for the JRA55 forcing 
# fields prepared by prepocess.sh. The perturbations are created by
# FILL THIS IN LATER

# Author: Francois Massonnet
# Python translation: Molly Wieringa
# Date: 2023-06-26
# =========================================================================
# =============================== History =================================
# Creation of the original R script: 2016-02-02, Francois Massonnet
# Creation of this python script: 2023-06-26, Molly Wieringa
# =========================================================================
# ============================== Modules ==================================
import numpy as np
import xarray as xr
import os
import sys
# ============================== Options ==================================
dir_vars  = ['t_10', 'q_10', 'u_10', 'v_10', 'lwdn', 'swdn', 'prec']
file_vars = ['t_10', 'q_10', 'u_10', 'v_10', 'lwdn', 'swdn', 'prec']

# set the directory for the annual differences in forcings
diff_dir = '../../interim/JRA55/diffs/'

# set the time period used to calculated annual differences
yearbp = 1990
yearep = 2019

# set the years for which new forcings must be perturbed
yearb = int(sys.argv[1])
yeare = int(sys.argv[2])

# set the number of perturbations (the number of desired ensemble members)
npert = 30

# ============================== Routine ==================================

nvar = len(dir_vars)
nyears_ref = yearep - yearbp + 1
nyears_act = yeare - yearb + 1
nsample = nyears_ref - 1

# print the start of the script
print('#=========================== BEGIN =================================#')

# loop through each variable
for j in range(0,nvar):
    print('Processing variable ' + dir_vars[j])

    # Step 1: Recording the perturbations from the available samples
    for y in range(yearbp + 1, yearep + 1):
        print('Reading data for ' + str(y) + '-' +str(y-1))
        filein = diff_dir + '/diff_JRA.v1.5_'+ dir_vars[j] + '_daily_' + str(y) + '-' + str(y-1) + '.nc'
        ds = xr.open_dataset(filein)

        # extract an array of just the variable of interest
        array = ds[file_vars[j]].values
        
        # replace any nans in the array with 0
        array[np.isnan(array)] = 0
        
        # if this is the first year, generate an empty state array
        if y == yearbp + 1:
            ny = array.shape[0]
            nx = array.shape[1]
            nt = array.shape[2]
            ns = ny*nx*nt
            state = np.zeros((ns,nsample))

        # reshape the array into a vector
        vector = array.reshape(ns,1)

        # store the vector in the state array
        state[:,y-yearbp-1] = vector[:,0]

    # Step 2: Center the data by removing the mean
    print('Centering the data')
    state_mean = np.mean(state, axis=1)
    anoms = state - state_mean[:,None]
    print('Data centered!')

    # Step 3: Calculate the perturbations
    for y in range(yearb, yeare + 1):
        print('Calculating perturbations for ' + dir_vars[j] + ' in year ' + str(y))

        for p in range(1,npert+1):
            print('Perturbing member ' + str(p) + ' of ' + str(npert))

            # Creating a seed for reproducibility
            # If the year is 1987 and the perturbation number is 302
            # then the seed is 1000 * 1987 + 302 = 1987302.
            # This is then a (relatively) unique identifier.
            
            # set the seed
            unq_seed = 1000 * y + p
            np.random.seed(unq_seed)

            # generate an array of random numbers between 0 and 1 with dimensions(nsample,1)
            z = np.random.rand(nsample,1)

            # generate the perturbation
            pert = np.matmul(anoms, z) * 1/np.sqrt(nsample-1)
            pert = pert.reshape(ny,nx,nt)

            # print first and last values of the perturbation
            print('First value of perturbation: ' + str(z[0,0]))
            print('Last value of perturbation: ' + str(z[-1,0]))

            # replace the array values with the perturbation (pert) matrix
            # which should retain the same dimensions as the original array
            new_array = ds[file_vars[j]]
            new_array.values = pert

            # create a pertubrations subdirectory if it doesn't already exist
            if not os.path.exists('../../interim/JRA55/perturbations'):
                os.makedirs('../../interim/JRA55/perturbations')    
            
            # save the perturbations to a netcdf file in the perturbations subdirectory
            fileout = '../../interim/JRA55/perturbations/mem'+'%02d' % p +'_JRA.v1.5_' + dir_vars[j] + '_' + str(y) + '.nc'
            new_array.to_netcdf(fileout)

            # Print completion of each perturbation member
            print('Perturbation member ' + str(p) + ' of ' + str(npert) + ' complete!')

    # Print completion of each variable
    print('Perturbations for ' + dir_vars[j] + ' complete!')

# Print completion of the script
print('All perturbations complete!')
print('#============================= END =================================#')

# =========================================================================



