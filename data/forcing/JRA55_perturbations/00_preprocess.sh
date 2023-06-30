#!/bin/bash -l

# ============================== Introduction ================================
# Author - F. Massonnet
# Editor - M. Wieringa
# Purpose- Prepare JRA55 forcing set to create perturbations later
# What the script does:
#   1) Make daily means in the case atmospheric data is at higher frequency
#   2) Remove leap days if any
#   3) Computes year-to-year differences
#
# The year-to-year differences are then used to generate perturbations
# in a second script.
#
# Takes 3 arguments: variable, first perturbed year, last perturbed year
#
# History - June 2023: creation for JRA55 perturbation from DFS5.2 perturbations
# =============================================================================

set -o nounset # Prevent unset variables from being used
set -o errexit # Exit if any error occurs
set -x         # Print each command before executing it

# ============================ User Input =====================================
# variable options are t_10, q_10, u_10, v_10, lwdn, swdn, precip, runoff?
var=$1  # first argument read as var

# years defining the period considered. If perturbations have to be generated 
# for 1980-1990 but based on anomalies of the period 1975-1985, the longest 
# period has to be set: 1975-1990

yearb=$2    # second argument read as yearb
yeare=$3    # third argument read as yeare

# directory of the source of the data (i.e., the original files)
sourcedir=../../raw/JRA55/

# working directory
workdir=../../interim/JRA55/

# =============================================================================
# Script Starts
# =============================================================================

# make working directory
mkdir -p $workdir
echo "Working directory is $workdir"

# ============================ Preprocessing ==================================
# Set up case specific variables
case ${var} in 
    t_10)
        min=100.0 	# Min and max values allowed
        max=400.0
        freq=3hour
        fvar=${var} 
        ;;
    q_10)
        min=0.0 	# Min and max values allowed
        max=0.1
        freq=3hour
        fvar=${var} 
        ;;
    u_10)
        min=-100.0 	# Min and max values allowed
        max=100.0
        freq=3hour
        fvar=${var} 
        ;;
    v_10)
        min=-100.0 	# Min and max values allowed
        max=100.0
        freq=3hour
        fvar=${var} 
        ;;
    lwdn)
        min=0.0 	# Min and max values allowed
        max=125.0   # Calculated from Massonnet's bound for daily lwnd (1000/8)
        freq=3hour
        fvar=${var} 
        ;;
    swdn)
        min=0.0 	# Min and max values allowed
        max=125.0   # Calculated from Massonnet's bound for daily swnd (1000/8)
        freq=3hour
        fvar=${var} 
        ;;
    prec)
        min=0.0 	# Min and max values allowed
        max=0.00125 # Calculated from Massonnet's bound for daily prec (0.01/8)
        freq=3hour
        fvar=${var} 
        ;;

    *)
    echo "Variable ${var} not recognized"
    exit
esac

# Cycle through each yeaer
for year in `seq ${yearb} ${yeare}`; 
do
    echo "Processing year ${year} / ${yeare}"

    # get the symbolic link's true directory and file name
    file=`readlink -v ${sourcedir}${var}/JRA.v1.5.${var}.*.${year}.*.nc`

    # reset valid range in the file's attributes 
    ncatted -O -a valid_range,${fvar},m,f,"${min},${max}" ${file} tmp.${var}.${year}.nc
    
    # set the time axis 
    cdo settaxis,${year}-01-01,00:00,${freq} tmp.${var}.${year}.nc ${workdir}/JRA.v1.5_${var}_${freq}_${year}.nc 
    
    # remove temporary file
    rm tmp.${var}.${year}.nc

    # calculate daily means
    if [ ${freq}!=1day ]; then
        cdo daymean ${workdir}/JRA.v1.5_${var}_${freq}_${year}.nc ${workdir}/JRA.v1.5_${var}_daily_${year}.nc
    else
        cp ${workdir}/JRA.v1.5_${var}_${freq}_${year}.nc ${workdir}/JRA.v1.5_${var}_daily_${year}.nc
    fi

    # remove leap days if any
    ndays=`cdo ntime ${workdir}/JRA.v1.5_${var}_daily_${year}.nc`
    printf "Number of days in year ${year} is ${ndays}\n"
    if [ ${ndays}==366 ]
    then
        cdo delete,day=29,month=2 ${workdir}/JRA.v1.5_${var}_daily_${year}.nc ${workdir}/JRA.v1.5_${var}_daily_${year}_noleap.nc
        mv ${workdir}/JRA.v1.5_${var}_daily_${year}_noleap.nc ${workdir}/daily/JRA.v1.5_${var}_daily_${year}.nc
    else
        if [ ${ndays}!=365 ]
        then
            echo "Number of days in year ${year} is not 365 or 366"
            exit
        fi
    fi
    
    # if daily and diff subdirectories do not exist, make them
    mkdir -p ${workdir}/daily
    mkdir -p ${workdir}/diffs
    mkdir -p ${workdir}/${freq}

    # calculate annual differences as long as within prescribed yearly range and save to diffs subdirectory
    if [ ${year} -ge $((${yearb} + 1)) ]
    then
        cdo sub ${workdir}/JRA.v1.5_${var}_daily_${year}.nc ${workdir}/daily/JRA.v1.5_${var}_daily_$((${year} - 1)).nc ${workdir}/diff_JRA.v1.5_${var}_daily_${year}-$(( ${year} - 1 )).nc
        mv ${workdir}/diff_JRA.v1.5_${var}_daily_${year}-$(( ${year} - 1 )).nc ${workdir}/diffs/diff_JRA.v1.5_${var}_daily_${year}-$(( ${year} - 1 )).nc
    fi

    # move daily files to daily subdirectory
    mv ${workdir}/JRA.v1.5_${var}_daily_${year}.nc ${workdir}/daily/JRA.v1.5_${var}_daily_${year}.nc

    # move the 3-hour files to 3-hour subdirectory
    mv ${workdir}/JRA.v1.5_${var}_${freq}_${year}.nc ${workdir}/${freq}/JRA.v1.5_${var}_${freq}_${year}.nc
    
done

# Progress report
echo "Preprocessing done- script successfully finished"
# =============================================================================