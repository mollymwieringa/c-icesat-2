#!/bin/bash
#PBS -N postprocess_prec_2000-2010
#PBS -A UWAS0083
#PBS -l select=1:ncpus=1:mem=10GB
#PBS -l walltime=12:00:00
#PBS -q economy
#PBS -j oe
#PBS -m ae
#PBS -M mmw906@uw.edu

# call the 02_postprocess.sh script in this same directory
bash 02_postprocess.sh prec 2000 2010