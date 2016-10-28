#!/bin/sh 
#BSUB -L /bin/sh
#BSUB -P GFS-T2O
#BSUB -oo /gpfs/hps/ptmp/Fanglin.Yang/log.weights
#BSUB -eo /gpfs/hps/ptmp/Fanglin.Yang/log.weights
#BSUB -J weights_fv3
#BSUB -q dev
#BSUB -M 128 
#BSUB -x
#BSUB -W 10:00
#BSUB -cwd /gpfs/hps/ptmp/Fanglin.Yang
#BSUB -extsched 'CRAYLINUX[]'
set -ax

 . $MODULESHOME/init/sh
module load PrgEnv-intel
#--------------------------------------------------

export home_dir=/gpfs/hps/emc/global/noscrub/Fanglin.Yang/NGGPS
export script_dir=$home_dir/ush
export exec_dir=$home_dir/exec
export fix_fv3_dir=$home_dir/fix
export fregrid=$home_dir/exec/fregrid_parallel
export TMPDIR=/gpfs/hps/ptmp/$LOGNAME/fv3_weight


#--global lat-lon array size
#----------------------------------------------------------
for GG in 1deg 0p5deg 0p25deg 0p125deg; do
#----------------------------------------------------------

if [ $GG = 1deg    ];  then  export nlon=360 ;  export nlat=180 ;fi  
if [ $GG = 0p5deg  ];  then  export nlon=720 ;  export nlat=360 ;fi  
if [ $GG = 0p25deg ];  then  export nlon=1440 ; export nlat=720 ;fi  
if [ $GG = 0p125deg ]; then  export nlon=2880 ; export nlat=1440 ;fi  

#----------------------------------------------------------
for CASE in C48  C96  C192  C384  C768  C1152  C3072; do
#----------------------------------------------------------
max_core=24
export NODES=3; export thread=1
if [ $CASE = C3072 ]; then export NODES=21; export thread=4; fi
export npes=$(((NODES-1)*max_core/thread))
 
export workdir=$TMPDIR/${CASE}_${GG}
mkdir -p $workdir; cd $workdir ||exit 8

export native_grid=$fix_fv3_dir/$CASE/${CASE}_mosaic.nc
export  remap_file=$fix_fv3_dir/$CASE/remap_weights_${CASE}_${GG}.nc

#NOTE: we are placing the first process on a node by itself to get the memory it needs
#      these npes will be tightly packed on the remaining nodes

aprun -n 1 -d 24 $fregrid --input_mosaic $native_grid \
                    --nlon $nlon --nlat $nlat \
                    --remap_file $remap_file \
                    --debug : \
   -n $npes -d $thread $fregrid --input_mosaic $native_grid \
                    --nlon $nlon --nlat $nlat \
                    --remap_file $remap_file \
                    --debug

done
done
exit
