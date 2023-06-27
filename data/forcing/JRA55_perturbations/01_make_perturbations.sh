#!/bin/bash -l
#PBS -N make_perturbations
#PBS -A UWAS0083
### Request one chunk of resources with 1 CPU and 10 GB of memory
#PBS -l select=1:ncpus=1:mem=10GB
#PBS -l walltime=06:00:00
#PBS -q economy
#PBS -j oe
#PBS -m ae
#PBS -M mmw906@uw.edu

# ============================== Introduction =================================
# Author - M. Wieringa
# Purpose- Create perturbations of JRA55 forcing from preprocessed data; 
#          perturbations are based on year-to-year differences and maintain
#          consistent covariance structure.
# What the script does:
#   -  Calls python script mkpert.py with inputs on years to perturb
#      The python script generates perturbations based on interannual variability
#      and saves them to an interim directory (interim/JRA55/perturbations) that 
#      is symbolically linked to a corresponding directory in SCRATCH. 
#
# Takes input from 00_preprocess.sh
#
# -------------------------- Notes on PBS settings ----------------------------
# When run on NCAR's Cheyenne supercomputer, the PBS settings should be
# determined based on the following observation:
#   -  The script takes ~1 hour to completely process 5 years of perturbations 
#      for 4/7 variables and 30 ensemble members.
# -----------------------------------------------------------------------------
#
# History - June 2023: creation for JRA55 perturbation 
# =============================================================================

export TMPDIR=/glade/scratch/$USER/temp
mkdir -p $TMPDIR

### Load Python module and activate NPL environment
module load ncarenv python
conda activate c-icesat-2

### Run analysis script
python mkpert.py 2006 2021
