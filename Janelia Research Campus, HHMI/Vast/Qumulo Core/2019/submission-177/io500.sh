#!/bin/bash -e
# WARNING: This script was automatically created using ./io-500-gen.sh config-10_48.sh
# Any modifications (below this line) will be lost if io-500-gen.sh is run again
# However, you may modify/tune this script manually or modify the generator to create an improved io-500.sh
# Put your batch submission commands QSUB | PBS -n XX

echo
RESULT=config-10_48-result-$(date +%s).txt
(
io500_info_submitter="Scientific Computing Systems"
io500_info_institution="HHMI Janelia Research Campus"
io500_info_system="nrs"
io500_info_storage_install_date="9/2016"
io500_info_storage_vendor="Qumulo"
io500_info_filesystem_name="Qumulo Core"
io500_info_filesystem_type="Scale out NFS"
io500_info_filesystem_version="2.13.0"
io500_info_client_nodes="10"
io500_info_client_procs_per_node="48"
io500_info_client_operating_system="Scientific Linux"
io500_info_client_operating_system_version="7.6"
io500_info_client_kernel_version="3.10.0-957.10.1.el7.x86_64"
io500_info_md_nodes="20"
io500_info_md_storage_devices="260"
io500_info_md_storage_type="SSD"
io500_info_md_volatile_memory_capacity="128GB"
io500_info_md_storage_interface="SATA"
io500_info_md_network="40GbE"
io500_info_ds_nodes="20"
io500_info_ds_storage_devices="520"
io500_info_ds_storage_type="HDD"
io500_info_ds_volatile_memory_capacity="128GB"
io500_info_ds_storage_interface="SATA"
io500_info_ds_network="40GbE"

echo
echo -n "[START TIME] "
date --rfc-3339=seconds
mkdir -p ./datafiles-10.48/ior_easy ./datafiles-10.48/ior_hard ./datafiles-10.48/mdt_hard ./datafiles-10.48/mdt_easy ./datafiles-10.48/pfind_results
# Please add in io500_prepare() additional scripts to setup/prepare the directories like lfs setstripe
ulimit -n 4096

echo
echo [IOR EASY WRITE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//ior --posix.odirect -t 1m -b 10000m -F -w -C -Q 1 -g -G 27 -k -e -o ./datafiles-10.48/ior_easy/ior_file_easy -O stoneWallingStatusFile=./datafiles-10.48/ior_easy/stonewall -O stoneWallingWearOut=1 -D 300

echo
echo [MDTEST EASY WRITE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -n 10000 -u -L -N 1 -C -F -d ./datafiles-10.48/mdt_easy -x ./datafiles-10.48/mdt_easy-stonewall -W 300

echo
echo [CREATING TIMESTAMP]
echo -n "time: "; date +%s.%N
touch ./datafiles-10.48/timestampfile

echo
echo [IOR HARD WRITE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//ior --posix.odirect -s 4500 -w -C -Q 1 -g -G 27 -k -e -t 47008 -b 47008 -o ./datafiles-10.48/ior_hard/IOR_file -O stoneWallingStatusFile=./datafiles-10.48/ior_hard/stonewall -O stoneWallingWearOut=1 -D 300

echo
echo [MDTEST HARD WRITE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -N 1 -n 1500 -C -t -F -w 3901 -e 3901 -d ./datafiles-10.48/mdt_hard -x ./datafiles-10.48/mdt_hard-stonewall -W 300

echo
echo [PFIND EASY]
echo -n "time: "; date +%s.%N
# You may change the find command defining the io_500_userdefined_find() function
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//pfind ./datafiles-10.48 -newer ./datafiles-10.48/timestampfile -size 3901c -name *01* -N -P -C -s 300 -D rates
echo -n "time: "; date +%s.%N

echo
echo [IOR EASY READ]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//ior --posix.odirect -t 1m -b 10000m -F -r -R -C -Q 1 -g -G 27 -k -e -o ./datafiles-10.48/ior_easy/ior_file_easy -O stoneWallingStatusFile=./datafiles-10.48/ior_easy/stonewall

echo
echo [MDTEST EASY STAT]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -n 10000 -u -L -N 1 -T -F -d ./datafiles-10.48/mdt_easy -x ./datafiles-10.48/mdt_easy-stonewall

echo
echo [IOR HARD READ]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//ior --posix.odirect -s 4500 -r -R -C -Q 1 -g -G 27 -k -e -t 47008 -b 47008 -s 4500 --posix.odirect -o ./datafiles-10.48/ior_hard/IOR_file -O stoneWallingStatusFile=./datafiles-10.48/ior_hard/stonewall

echo
echo [MDTEST HARD STAT]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -N 1 -n 1500 -T -t -F -w 3901 -e 3901 -d ./datafiles-10.48/mdt_hard -x ./datafiles-10.48/mdt_hard-stonewall

echo
echo [MDTEST EASY DELETE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -n 10000 -u -L -N 1 -r -F -d ./datafiles-10.48/mdt_easy -x ./datafiles-10.48/mdt_easy-stonewall

echo
echo [MDTEST HARD READ]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -N 1 -n 1500 -E -t -F -w 3901 -e 3901 -d ./datafiles-10.48/mdt_hard -x ./datafiles-10.48/mdt_hard-stonewall

echo
echo [MDTEST HARD DELETE]
echo -n "time: "; date +%s.%N
mpirun -np 480 -ppn 48 -f hostfile-10sl -bootstrap ssh ./bin//mdtest --posix.odirect -N 1 -n 1500 -r -t -F -w 3901 -e 3901 -d ./datafiles-10.48/mdt_hard -x ./datafiles-10.48/mdt_hard-stonewall

echo
echo Deleting IO-500 ./datafiles-10.48
echo -n "time: "; date +%s.%N
rm -rf ./datafiles-10.48/ior_easy ./datafiles-10.48/ior_hard ./datafiles-10.48/mdt_hard ./datafiles-10.48/mdt_easy ./datafiles-10.48/pfind_results ./datafiles-10.48/timestampfile ./datafiles-10.48/mdt_easy-stonewall ./datafiles-10.48/mdt_hard-stonewall
echo -n "[END TIME] "
date --rfc-3339=seconds
echo "[IO-500 COMPLETED] Result also in ${RESULT}; Now use io-500-score.sh to compute the score"
) | tee ${RESULT}
