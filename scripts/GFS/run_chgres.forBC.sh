#!/bin/sh
#----AWS SLURM JOBCARD
#SBATCH --partition=misccomp
#SBATCH -N 1 --ntasks-per-node=36
#SBATCH -o log.forBC.regional.%j
#SBATCH -e log.forBC.regional.%j

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
MEMBER_DOWNLOAD_COMBINE=/lustre/ensemble/20210303/download/1/combine/
date_prv=20210302
hour_from=18
#
# set the links to use the 4 halo grid and orog files
# these are necessary for creating the boundary data
#
# ln -sf $FIXDIR/$CASE/${CASE}_grid.tile7.halo4.nc $FIXDIR/$CASE/${CASE}_grid.tile7.nc
# ln -sf $FIXDIR/$CASE/${CASE}_oro_data.tile7.halo4.nc $FIXDIR/$CASE/${CASE}_oro_data.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.vegetation_greenness.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.vegetation_greenness.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.soil_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.soil_type.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.slope_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.slope_type.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.substrate_temperature.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.substrate_temperature.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.facsf.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.facsf.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.maximum_snow_albedo.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.maximum_snow_albedo.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.snowfree_albedo.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.snowfree_albedo.tile7.nc
# ln -sf $FIXDIR/$CASE/fix_sfc/${CASE}.vegetation_type.tile7.halo4.nc $FIXDIR/$CASE/${CASE}.vegetation_type.tile7.nc

WORKDIR=/lustre/ensemble/20210303/stmp1/1/chgres_fv3.forBC.grib2.c3357
rm -fr $WORKDIR
mkdir -p $WORKDIR
cd $WORKDIR
#
# create namelist and run chgres_cube
#
cp ${BASEDIR}/exec/chgres_cube .
chour=9
end_hour=66
bc_interval=3
fhour=`expr $chour - 6`
while (test "$chour" -le "$end_hour")
 do
  if [ $chour -lt 10 ]; then
   hour_name='00'$chour
   new_hour_name='00'$fhour
  elif [ $chour -lt 100 ]; then
   hour_name='0'$chour
   new_hour_name='0'$fhour
  else
   hour_name=$chour
   new_hour_name=$fhour
  fi
#
  if [ $chour -le 15 ]; then
   new_hour_name='00'$fhour
  elif [ $chour -le 105 ]; then
   new_hour_name='0'$fhour
  else
   new_hour_name=$fhour
  fi

cat <<EOF >$WORKDIR/fort.41
&config
 mosaic_file_target_grid="$FIXDIR/C$res/C${res}_mosaic.nc"
 fix_dir_target_grid="$FIXDIR/C$res"
 orog_dir_target_grid="$FIXDIR/C$res"
 orog_files_target_grid="C${res}_oro_data.tile7.halo4.nc"
 vcoord_file_target_grid="${BASEDIR}/fix/fix_am/global_hyblev.l65.txt"
 data_dir_input_grid="${MEMBER_DOWNLOAD_COMBINE}/gfs.${date_prv}/${hour_from}"
 grib2_file_input_grid="gfs.t${hour}z.pgrb2.0p25.f${hour_name}"
 varmap_file="${BASEDIR}/parm/varmap_tables/GFSphys_var_map.txt"
 input_type="grib2"
 cycle_mon=$month
 cycle_day=$day
 cycle_hour=$hour
 convert_atm=.true.
 convert_sfc=.false.
 convert_nst=.false.
 halo_bndy=4
 regional=2
 halo_blend=10
/
EOF
#
#Run chgres
#
 time srun -l --mpi=pmi2 ./chgres_cube
 chour=`expr $chour + $bc_interval`
 fhour=`expr $fhour + $bc_interval`
 mv gfs.bndy.nc $FIXDIR/C${res}/gfs_bndy.tile7.$new_hour_name.nc
done
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

