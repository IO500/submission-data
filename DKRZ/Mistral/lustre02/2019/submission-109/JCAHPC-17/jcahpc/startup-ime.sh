#!/bin/sh
#PJM -L rscgrp=regular-flat
#PJM -L node=2048
#PJM --mpi proc=16384
#PJM -L elapse=2:00:00
#PJM -g xg17i000
#PJM -j

DIR=/cache/xg17i000/x10007
IO500DIR=${DIR}/io500
export I_MPI_PIN_PROCESSOR_EXCLUDE_LIST=0,68,136,204
# Command to start an MPI application
mpirun="mpiexec.hydra -n ${PJM_MPI_PROC}"
workdir=${IO500DIR}/io500-data.$$
output_dir=${IO500DIR}/io500-results-${PJM_NODE}-${PJM_PROC_BY_NODE}.$$

mkdir -p ${workdir} ${output_dir} || exit 1

# Tunable parameters, feel free to change them
# The write phase for each benchmark (ior_easy, ior_hard, mdtest_easy, mdtest_hard) must be 5 minutes
ior_easy_params="-t 2048k -b 15g"
ior_hard_writes_per_proc=220000
mdtest_easy_files_per_proc=500
mdtest_hard_files_per_proc=20
# If to use mdreal
#params_mdreal="-P=5000 -I=1000"
subtree_to_scan_config=$output_dir/subtree.cfg

# If you use the find command from find/io500-find.sh, you can specify how many directories to scan to limit its runtime
# Here scan 100 dirs
# The subtrees to scan from md-easy, each contains mdtest_easy_files_per_proc files
( for I in $(seq 100) ; do
  echo mdtest_tree.$I.0
done ) > $subtree_to_scan_config || exit 1

# Define the executables for the commands
find_cmd=${DIR}/bin/io500-find.sh
ior_cmd=${DIR}/bin/ior
mdtest_cmd=${DIR}/bin/mdtest
mdreal_cmd=

# Add whatever you want to do for preparing the workdirectory
# Here we precreate directories for lustre with the appropriate striping
#mkdir -p ${workdir}/ior_easy
#lfs setstripe --stripe-count 2  ${workdir}/ior_easy

#mkdir -p ${workdir}/ior_hard
#lfs setstripe --stripe-count 100  ${workdir}/ior_hard


# Now write the output/results  file
(
cd ${IO500DIR} # walk to the directory with the io_500_core script

# Add key/value pairs defining your system if you want
#echo "filesystem_utilization=$(df ${workdir})"
echo "date=$(date -I)"
#echo "queue="
echo "nodes=$PJM_NODE"
echo "ppn=$PJM_PROC_BY_NODE"
#echo "nodelist=$(cat $HYDRA_HOST_FILE)"
echo ior_easy_params=$ior_easy_params
echo ior_hard_writes_per_proc=$ior_hard_writes_per_proc
echo mdtest_easy_files_per_proc=$mdtest_easy_files_per_proc
echo mdtest_hard_files_per_proc=$mdtest_hard_files_per_proc

pwd
# Important: source the io 500 script:
source ./io_500_core.sh # Do not change the script
) 2>&1 | tee ${PJM_NODE}-${PJM_PROC_BY_NODE}.$$.out

# Cleanup some leftovers
rm -rf $workdir/
