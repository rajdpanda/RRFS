#!/bin/sh
#----AWS SLURM JOBCARD
#SBATCH --partition=misccomp
#SBATCH -N 1 --ntasks-per-node=36
#SBATCH -t 0:30:00
#SBATCH -o log.hwt.regional.%j
#SBATCH -e log.hwt.regional.%j
#SBATCH --cpus-per-task=1

set +x
module purge
module load intel/19.0.5.281 intelmpi
module use /contrib/apps/modules
module load hpc-stack/1.1.0
module list
ulimit -s unlimited
ulimit -a
set -ax
#
res=3357            # resolution of tile: 48, 96, 192, 384, 96, 1152, 3072
CASE=C3357
DATE=2021030218   # format yyyymmddhh yyyymmddhh ...
ymd=`echo $DATE | cut -c 1-8`
month=`echo $DATE | cut -c 5-6`
day=`echo $DATE | cut -c 7-8`
hour=`echo $DATE | cut -c 9-10`
# Threads are useful when processing spectal gfs data in
# sigio format.  Otherwise, use one thread.
export OMP_NUM_THREADS=1
export OMP_STACKSIZE=1024M
BASEDIR=/lustre/ensemble/UFS_UTILS
FIXDIR=/lustre/ensemble/20210303/stmp1/1
MEMBER_DOWNLOAD=/lustre/ensemble/20210303/download/1
#
# set the links to use the 4 halo grid and orog files
# these are necessary for creating the boundary data
#
 ln -sf $FIXDIR/$CASE/${CASE}_grid.tile7.halo4.nc $FIXDIR/$CASE/${CASE}_grid.tile7.nc
 ln -sf $FIXDIR/$CASE/${CASE}_oro_data.tile7.halo4.nc $FIXDIR/$CASE/${CASE}_oro_data.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.vegetation_greenness.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.vegetation_greenness.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.soil_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.soil_type.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.slope_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.slope_type.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.substrate_temperature.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.substrate_temperature.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.facsf.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.facsf.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.maximum_snow_albedo.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.maximum_snow_albedo.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.snowfree_albedo.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.snowfree_albedo.tile7.nc
 ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.vegetation_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.vegetation_type.tile7.nc
WORKDIR=/lustre/ensemble/20210303/stmp1/1/chgres_fv3
rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR
#
# create namelist and run chgres_cube
#
cp $BASEDIR/exec/chgres_cube .
cat <<EOF >$WORKDIR/fort.41
&config
 mosaic_file_target_grid="$FIXDIR/C$res/C${res}_mosaic.nc"
 fix_dir_target_grid="$FIXDIR/C$res"
 orog_dir_target_grid="$FIXDIR/C$res"
 orog_files_target_grid="C${res}_oro_data.tile7.halo4.nc"
 vcoord_file_target_grid="${BASEDIR}/fix/fix_am/global_hyblev.l65.txt"
 mosaic_file_input_grid="NULL"
 orog_dir_input_grid="NULL"
 orog_files_input_grid="NULL"
 data_dir_input_grid="${MEMBER_DOWNLOAD}/gfs.20210302/${hour}"
 atm_files_input_grid="gfs.t${hour}z.atmf006.nemsio"
 sfc_files_input_grid="gfs.t${hour}z.sfcf006.nemsio"
 cycle_mon=$month
 cycle_day=$day
 cycle_hour=$hour
 convert_atm=.true.
 convert_sfc=.true.
 convert_nst=.true.
 input_type="gaussian_nemsio"
 tracers="sphum","liq_wat","o3mr","ice_wat","rainwat","snowwat","graupel"
 tracers_input="spfh","clwmr","o3mr","icmr","rwmr","snmr","grle"
 regional=1
 halo_bndy=4
 halo_blend=10
/
EOF

time srun -l --mpi=pmi2 ./chgres_cube

# move output files to save directory
#
mv gfs_ctrl.nc $FIXDIR/C$res/gfs_ctrl.nc
mv gfs.bndy.nc $FIXDIR/C$res/gfs_bndy.tile7.000.nc
mv out.atm.tile7.nc $FIXDIR/C$res/gfs_data.tile7.nc
mv out.sfc.tile7.nc $FIXDIR/C$res/sfc_data.tile7.nc
#
#remove the links that were set above for the halo4 files
#
 rm $FIXDIR/$CASE/${CASE}_grid.tile7.nc
 rm $FIXDIR/$CASE/${CASE}_oro_data.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.vegetation_greenness.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.soil_type.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.slope_type.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.substrate_temperature.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.facsf.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.maximum_snow_albedo.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.snowfree_albedo.tile7.nc
 rm $FIXDIR/$CASE/${CASE}.vegetation_type.tile7.nc
exit 0
