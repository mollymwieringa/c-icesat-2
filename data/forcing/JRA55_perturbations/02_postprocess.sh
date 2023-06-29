#!/bin/bash

# ============================== Introduction =================================
# Author - F. Massonnet
# Editor - M. Wieringa
# Purpose- Process the perturbations of JRA55 forcing and add them to the
#          actual forcing.
# What the script does:
#   1) Interpolate from daily to 3hourly
#   2) Add to the true forcing
#
# Takes input from 01_make_perturbations.sh
# Takes 3 arguments: variable, first peturbed year, last perturbed year
#
# -------------------------- Notes on PBS settings ----------------------------
# When run on NCAR's Cheyenne supercomputer, the PBS settings were determined
# based on observation of the following:
#
# -----------------------------------------------------------------------------
# History - June 2023: creation for JRA55 perturbation 
# =============================================================================

set -o nounset # Treat unset variables as an error
set -o errexit # Stop script if command fails
set -x         # Echo commands to the terminal

# ============================ User Input =====================================
# Which variable of the JRA55 forcing set has to be perturbed?
# Possibilities: t_10, q_10, u_10, v_10, lwdn, swdn, precip read as an argument
var=$1  # first argument read as var

# What's the strength of the peturbations? 1 = same as interannual variability. 0.5 = half of it.
alpha=1.0

# First and end years for which a perturbation has to be created.
yearb=$2    # second argument read as yearb
yeare=$3  # third argument read as yeare

# First and end years defining the reference period on which
# the perturbations were created (must match those in preprocess.bash and in mkpert.R)
yearbp=2000
yearep=2021

# How many members are we going to perturb?
# NOTE: Usually the first member ("fc0") is the true forcing so it should *NOT* be perturbed.
nmb=1
nme=5

# What are the directories of input and output?
workdir=`realpath ../../interim/JRA55/perturbations/`
# If outdir does not exist, create it
mkdir -p ../../interim/JRA55/postprocessed/
outdir=`realpath ../../interim/JRA55/postprocessed/`
ogdir=`realpath ../../interim/JRA55/3hour/`

# =============================================================================
# ============================== Script Starts ================================
echo "Workdir is $workdir"

case ${var} in
    t_10)
        min=100.0 	# Min and max values allowed
        max=400.0
        freq=3hour  # Frequency of availability
        ntim=2920   # Number of time steps in a year
        fvar=${var} # Name of the variable in the NetCDF
        ;;
    q_10)
        min=0.0
        max=0.1
        freq=3hour
        ntim=2920
        fvar=${var}
        ;;
    u_10)
        min=-100.0
        max=100.0
        freq=3hour
        ntim=2920
        fvar=${var}
        ;;
    v_10)
        min=-100.0
        max=100.0
        freq=3hour
        ntim=2920
        fvar=${var}
        ;;
    lwdn)
        min=0.0
        max=1000.0
        freq=3hour
        ntim=2920
        fvar=${var}
        ;;
    swdn)
        min=0.0
        max=1000.0
        freq=3hour
        ntim=2920
        fvar=${var}
        ;;
    prec)
        min=0.0
        max=0.01
        freq=3hour
        ntim=2920
        fvar=prec
        ;;
    *)
    echo "Variable ${var} not recognized"
    exit 
esac

# Cycle over years
for year in `seq ${yearb} ${yeare}`
do 
    for member in `seq ${nmb} ${nme}`
    do 
        if [ ${member} == 0 ]
        then 
            echo "Warning!"
            echo "Member 0 is the true forcing. It should not be perturbed."
            echo "By creating a perturbation for member 0, you are overwriting the true forcing."
            echo "For this reason, this script is aborting."
            echo "To continue, change nmb to something > 1"
            exit
        fi
        mem=$(printf "%02d" ${member})

        # There is a small trick being employed here. If we have 3 days of data and asked for
        # 3-hourly interpolation, we will have only 17 points and not 24. This is because we have 
        # in fact (ndays - 1) * 8 + 1 points. So we need to append the last day to the data twice 
        # and remove the last time frame. 

        # Make the record dimension for the file of interest time
        ncks --mk_rec_dmn time                     ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc     ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.0
        
        # Extract the last time frame
        ncks -F -O -d time,365,365                 ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.0   ${workdir}/mem${mem}_${var}_${year}_tmp1.nc

        # Append the last time frame
        ncrcat -F -O                               ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.0   ${workdir}/mem${mem}_${var}_${year}_tmp1.nc        ${workdir}/mem${mem}_${var}_${year}_tmp2.nc

        # Set time axis
        cdo settaxis,${year}-01-01,00:00:00,1day   ${workdir}/mem${mem}_${var}_${year}_tmp2.nc         ${workdir}/mem${mem}_${var}_${year}_tmp3.nc

        # Interpolate to 3-hourly
        cdo inttime,${year}-01-01,00:00:00,${freq} ${workdir}/mem${mem}_${var}_${year}_tmp3.nc         ${workdir}/mem${mem}_${var}_${year}_tmp4.nc

        # Remove the last time frame
        ncks -F -O -d time,1,${ntim}               ${workdir}/mem${mem}_${var}_${year}_tmp4.nc         ${workdir}/mem${mem}_${var}_${year}_tmp5.nc

        # Add the desired fraction alpha of the perturbation to the true forcing
        cdo add -mulc,${alpha}                     ${workdir}/mem${mem}_${var}_${year}_tmp5.nc         ${ogdir}/JRA.v1.5_${var}_${freq}_${year}.nc ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.1

        # Ensure physical bounds
        cdo setrtoc,-10000000000,${min},${max}     ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.1   ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.2
        cdo setrtoc,${max},10000000000,${max}      ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.2   ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.3

        # Set the time units to allow nice reading
        cdo settunits,years                        ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.3   ${outdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc

        # Add description in the header
        ncatted -O -a description,${fvar},a,c,"Perturbed version of JRA55 variable ${fvar} for year ${year} (member mem${mem}). Strength of perturbation is ${alpha} times the year-to-year differences estimated over the ${yearbp}-${yearep} reference period. For more details: mmw906@uw.edu or francois.massonnet@bsc.es" ${outdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc

        # Give general permission to access, read, and write the file
        chmod 777 ${outdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc

        # Clean up by removing all the temporary files
        rm -f ${workdir}/mem${mem}_JRA.v1.5_${var}_${year}.nc.? ${workdir}/mem${mem}_${var}_${year}_tmp?.nc

    done
done

echo "Postprocessing of JRA55 perturbations finished!"
echo "Output is in ${outdir}"

# ============================== Script Ends ==================================
# =============================================================================