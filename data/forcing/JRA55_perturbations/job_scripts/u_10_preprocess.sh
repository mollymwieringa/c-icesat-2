#!/bin/bash
#PBS -N preprocess_u_10
#PBS -A UWAS0083
#PBS -l select=1:ncpus=1:mem=10GB
#PBS -l walltime=01:00:00
#PBS -q economy
#PBS -j oe
#PBS -m ae
#PBS -M mmw906@uw.edu

# call the 02_postprocess.sh script in this same directory
bash 00_preprocess.sh u_10 1990 2021