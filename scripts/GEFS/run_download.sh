#!/bin/bash

mem_num=2
cp_from=2
Type="GEFS"
gep_num=1
date_cur=20210303
date_prv=20210302
hour_from=18
gfs_pfix=__GFS_PFIX__
gfs_file_atm=__GFS_FILE_ATM__
gfs_file_sfc=__GFS_FILE_SFC__
gfs_stub_b2=__GFS_STUB_B2__
gfs_stub_b2b=__GFS_STUB_B2B__
gefs_pfix_a=https://ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.20210302/18/atmos/pgrb2ap5
gefs_pfix_b=https://ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.20210302/18/atmos/pgrb2bp5
gefs_stub_a=t18z.pgrb2a.0p50.f0
gefs_stub_b=t18z.pgrb2b.0p50.f0
beg_hour=6
end_hour=66
RUNDIR=/lustre/ensemble/20210303
skip_hour=3

module load intel/19.0.5.281
module use -a /contrib/apps/modules
module load hpc-stack/1.1.0

DOWNLOAD_DIR=${RUNDIR}/download
MEMBER_DIR=${DOWNLOAD_DIR}/${mem_num}
MEMBER_SCRIPTS=${RUNDIR}/scripts/${mem_num}

if [ ! -d "$DOWNLOAD_DIR" ]; then
	cd $RUNDIR
	mkdir -p $DOWNLOAD_DIR
fi
if [ -d "$MEMBER_DIR" ]; then
	cd $RUNDIR
	rm -rf $MEMBER_DIR
	mkdir -p $MEMBER_DIR
else
	mkdir -p $MEMBER_DIR
fi

declare -a local add0
#Initialize an array for suffix numbers
for i in $(seq 0 "99")
do
        if [ "$i" -lt "10" ]; then
                add0[$i]="0"${i}
        else
                add0[$i]="$i"
        fi
done


if [ "$Type" == "GFS" ]; then
	cd $MEMBER_DIR
	mkdir -p gfs.${date_prv}/${hour_from}
	dirpath=${MEMBER_DIR}/gfs.${date_prv}/${hour_from}
	cd gfs.${date_prv}/${hour_from}
	url1=${gfs_pfix}/${gfs_file_atm}
	url2=${gfs_pfix}/${gfs_file_sfc}
        wget --directory=${dirpath} $url1 &
        wget --directory=${dirpath} $url2 &
	for i in $(seq "$beg_hour" "$skip_hour" "$end_hour")
	do
		url_a=${gfs_pfix}/${gfs_stub_b2}${add0[$i]}
                wget --directory=${dirpath} $url_a
                wait
		url_b=${gfs_pfix}/${gfs_stub_b2b}${add0[$i]}
                wget --directory=${dirpath} $url_b
                wait
	done
	cd $MEMBER_SCRIPTS
	python grib2_combine.py

fi
if [ "$Type" == "GEFS" ]; then
	cd $MEMBER_DIR
	mkdir -p geps.${date_prv}
        mkdir -p geps.${date_prv}/ap5
        mkdir -p geps.${date_prv}/bp5
        dirpath_a=${MEMBER_DIR}/geps.${date_prv}/ap5    
        dirpath_b=${MEMBER_DIR}/geps.${date_prv}/bp5    
	for i in $(seq "$beg_hour" "$skip_hour" "$end_hour")
	do
                url_a=${gefs_pfix_a}/gep${add0[$gep_num]}.${gefs_stub_a}${add0[$i]}
                wget --directory=${dirpath_a} $url_a
                wait
                url_b=${gefs_pfix_b}/gep${add0[$gep_num]}.${gefs_stub_b}${add0[$i]}
                wget --directory=${dirpath_b} $url_b
                wait
		cat ${dirpath_a}/gep${add0[$gep_num]}.${gefs_stub_a}${add0[$i]} ${dirpath_b}/gep${add0[$gep_num]}.${gefs_stub_b}${add0[$i]} > ${MEMBER_DIR}/gep${add0[$gep_num]}.${gefs_stub_b}${add0[$i]}
	done


fi

