On Github this directory will contain only the symlink for JRA55. In 
practice, this directory should link to a temporary data repository 
where large files can be manipulated, copied, and stored in interim 
versions between the data linked in the '/raw/' directory and the final 
desired file format. 
<br>
For the original processing for which the perturbation scripts in
../forcing/JRA55_perturbations were developed, this directory contained a 
symlink ('JRA55') that led to the following subdirectory structure on 
/glade/scratch/mollyw/archive/c-icesat-2/JRA55_perturbation <br>
- |---- JRA55_perturbation
    - |---- 3hour
        - |---- (file) JRA.v1.5_{var}/_3hour/_{year}.nc
    - |---- daily
        - |---- (file) JRA.v1.5_{var}/_daily/_{year}.nc
    - |---- diffs
        - |---- (file) diff_JRA.v1.5_{var}/_daily/_{year2}-{year1}.nc
    - |---- perturbations
        - |---- (file) mem{##}_JRA55.v1.5/_{var}/_{year}.nc
    - |---- postprocessed
        - |---- (file) mem{##}_JRA55.v1.5/_{var}/_{year}.nc
<br>
The files stored in the /perturbations subdirectory are used by
the 02_postprocess.sh script in ../forcing/JRA55_perturbations to 
generate the finalized atmospheric forcing files stored in the 
/postprocessed subdirectory.
<br>
From /postprocessed, the files should be eventually concatenated
into a single time-continuous file that can be used in CESM2's 
DATM model. 