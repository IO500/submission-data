#!/bin/bash
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.
# Please also edit 'extra_description' function.
#set -x

if [ "$1" == "" ]
then
	SCALE=1
else
	SCALE=$1
fi


NP=$(( $SCALE * 10 ))

echo "$SCALE processes per node for $NP processes."

set -euo pipefail  # better error handling

export BEEGFS_MOUNT=/burstbuffer
export OFS_MOUNT=${BEEGFS_MOUNT}/fast/jburto2

# turn these to True successively while you debug and tune this benchmark.
# for each one that you turn to true, go and edit the appropriate function.
# to find the function name, see the 'main' function.
# These are listed in the order that they run.
io500_run_ior_easy="True" # does the write phase and enables the subsequent read
io500_run_md_easy="True"  # does the creat phase and enables the subsequent stat
io500_run_ior_hard="True" # does the write phase and enables the subsequent read
io500_run_md_hard="True"  # does the creat phase and enables the subsequent read
io500_run_find="True"     
io500_run_ior_easy_read="True"
io500_run_md_easy_stat="True"
io500_run_ior_hard_read="True"
io500_run_md_hard_stat="True"
io500_run_md_hard_read="True"  
io500_run_md_easy_delete="True" # turn this off if you want to just run find by itself
io500_run_md_hard_delete="True" # turn this off if you want to just run find by itself
io500_run_mdreal="True"  # this one is optional
io500_cleanup_workdir="False"  # this flag is currently ignored. You'll need to clean up your data files manually if you want to.
io500_stonewall_timer=300 # Stonewalling timer, stop with wearout after 300s with default test, set to 0, if you never want to abort...
io500_clean_cache="False" # attempt to clean the cache after every benchmark, useful for validating the performance results and for testing with a local node; it uses the io500_clean_cache_cmd (can be overwritten); make sure the user can write to /proc/sys/vm/drop_caches
io500_stonewall_timer=300 # Stonewalling timer, set to 300 to be an official run; set to 0, if you never want to abort...
io500_rules="regular" # Choose regular for an official regular submission or scc for a Student Cluster Competition submission to execute the test cases for 30 seconds instead of 300 seconds

# to run this benchmark, find and edit each of these functions.
# please also edit 'extra_description' function to help us collect the required data.
function main {
  setup_directories
  setup_paths    
  setup_ior_easy # required if you want a complete score
  setup_ior_hard # required if you want a complete score
  setup_mdt_easy # required if you want a complete score
  setup_mdt_hard # required if you want a complete score
  setup_find     # required if you want a complete score
  setup_mdreal   # optional
  run_benchmarks
}

function setup_directories {
  # set directories for where the benchmark files are created and where the results will go.
  # If you want to set up stripe tuning on your output directories or anything similar, then this is good place to do it. 
  timestamp=`date +%Y.%m.%d-%H.%M.%S`           # create a uniquifier
  io500_workdir=$OFS_MOUNT/io500/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept

  mkdir -p $io500_workdir $io500_result_dir
  mkdir -p ${io500_workdir}/ior_easy ${io500_workdir}/ior_hard 
  mkdir -p ${io500_workdir}/mdt_easy ${io500_workdir}/mdt_hard 
  
  beegfs-ctl --mount=$BEEGFS_MOUNT --setpattern --numtargets=1 --chunksize=2048k  ${io500_workdir}/ior_easy
# stripe across all OSTs for ior_hard, 64k chunksize
# best pattern is minimal chunksize to fit one I/O in, regardless of RAID stripe.
  beegfs-ctl --mount=$BEEGFS_MOUNT --setpattern --numtargets=24 --chunksize=64k ${io500_workdir}/ior_hard
# turn off striping and use small chunks for mdtest
  beegfs-ctl --mount=$BEEGFS_MOUNT --setpattern --numtargets=1 --chunksize=128k ${io500_workdir}/mdt_easy
  beegfs-ctl --mount=$BEEGFS_MOUNT --setpattern --numtargets=1 --chunksize=128k ${io500_workdir}/mdt_hard
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  #io500_mpi_prefix="/usr/lib64/openmpi"
  #io500_mpi_prefix="/home/jburto2/openmpi/1.10.7"
  #io500_mpi_prefix=/opt/openmpi-1.10.7
  io500_mpi_prefix="/software/openmpi/4.0.1_gcc"
  io500_mpirun="$io500_mpi_prefix/bin/mpirun"
  io500_mpienv="-x LD_LIBRARY_PATH=/opt/pbs/default/lib:/opt/orangefs/lib"
  #io500_mpiargs="-np $NP --mca btl_tcp_if_exclude ib0 --mca btl ^openib --map-by node --machinefile /home/jburto2/hpccnodelistmpi --prefix $io500_mpi_prefix"
  #io500_mpiargs="-np $NP  ${io500_mpienv} --mca mpi_cuda_support 0 --map-by node --machinefile /home/jburto2/phase15mpi --prefix $io500_mpi_prefix"
  io500_mpiargs="-np $NP  ${io500_mpienv} --mca btl_openib_allow_ib true --mca mpi_cuda_support 0 --map-by node --machinefile /home/jburto2/hdrnodesmpi --prefix $io500_mpi_prefix"
}

function setup_ior_easy {
# 4M writes, 2049 GB per proc, file per proc. 
  io500_ior_easy_size=$((2049 * 1024 / $SCALE))
  io500_ior_easy_params="-t 2048k -b ${io500_ior_easy_size}m -F -a POSIX"
   
}

function setup_mdt_easy {
# 6 levels, 1 branches, unique dir per thread
# BeeGFS doesn't have distributed directories, so more directories = better distribution. 
  #io500_mdtest_easy_params="-z 6 -b 1 -u " 
  io500_mdtest_easy_params=" -u -L" 
  io500_mdtest_easy_files_per_proc=200000
}

function setup_ior_hard {
  if [ "$SCALE" == "1" ] 
  then
	# One process per node is significantly faster because of buffering.
  	io500_ior_hard_writes_per_proc=5000000
  else	
  	io500_ior_hard_writes_per_proc=$(( 5000000 / $SCALE ))
  fi

  io500_ior_hard_other_options=""
  io500_ior_hard_api="POSIX" 
  io500_ior_hard_api_specific_options=""
}

function setup_mdt_hard {
# Multiple directories might improve mdt_hard slightly, but this test is storage bound, not md bound.
  io500_mdtest_hard_files_per_proc="$(( 5000000 / $SCALE ))"
  io500_mdtest_files_per_proc=$(( 5000000 / $SCALE )) 
  io500_mdtest_hard_other_options=""
  io500_mdtest_hard_api="POSIX" 
  io500_mdtest_hard_api_specific_options=""
}

function setup_find {
  #
  # setup the find command. This is an area where innovation is allowed.
  #    There are three default options provided. One is a serial find, one is python
  #    parallel version, one is C parallel version.  Current default is to use serial.
  #    But it is very slow. We recommend to either customize or use the C parallel version.
  #    For GPFS, we recommend to use the provided mmfind wrapper described below.
  #    Instructions below.
  #    If a custom approach is used, please provide enough info so others can reproduce.

  # the serial version that should run (SLOWLY) without modification
  #io500_find_mpi="False"
  #io500_find_cmd=$PWD/bin/sfind.sh
  #io500_find_cmd_args=""

  # a parallel version in C, the -s adds a stonewall
  #   for a real run, turn -s (stonewall) off or set it at 300 or more
  #   to prepare this (assuming you've run ./utilities/prepare.sh already):
  #   > cd build/pfind
  #   > ./prepare.sh
  #   > ./compile.sh
  #   > cp pfind ../../bin/ 
  #   If you use io500_find_mpi="True", then this will run with the same
  #   number of MPI nodes and ranks as the other phases.
  #   If you prefer another number, and fewer might be better here,
  #   Then you can set io500_find_mpi to be "False" and write a wrapper
  #   script for this which sets up MPI as you would like.  Then change
  #   io500_find_cmd to point to your wrapper script. 
  io500_find_mpi="True"
  io500_find_cmd="$PWD/bin/pfind"
  io500_find_cmd_args="-s 100000 -r $io500_result_dir/pfind_results"
  
  # for GPFS systems, you should probably use the provided mmfind wrapper 
  # if you used ./utilities/prepare.sh, you'll find this wrapper in ./bin/mmfind.sh
  #io500_find_mpi="False"
  #io500_find_cmd="$PWD/bin/mmfind.sh"
  #io500_find_cmd_args=""
}

function setup_mdreal {
  io500_mdreal_params="-P=5000 -I=1000"
}

function run_benchmarks {
  # Important: source the io500_fixed.sh script.  Do not change it. If you discover
  # a need to change it, please email the mailing list to discuss
  source ./bin/io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.$timestamp.txt
}

# Add key/value pairs defining your system 
# Feel free to add extra ones if you'd like
function extra_description {
  # top level info
  io500_info_system_name='Palmetto burstbuffer AMD EPIC test'      # e.g. Oakforest-PACS
  io500_info_institute_name='Clemson University'   # e.g. JCAHPC
  io500_info_storage_age_in_months='0' # not install date but age since last refresh
  io500_info_storage_install_date='05/19'  # MM/YY
  io500_info_filesysem='BeeGFS'     # e.g. BeeGFS, DataWarp, GPFS, IME, Lustre
  io500_info_filesystem_version='7.1.3'
  # client side info
  io500_info_num_client_nodes="10"
  io500_info_procs_per_node="${SCALE}" 
  # server side info
  io500_info_num_metadata_server_nodes='4'
  io500_info_num_data_server_nodes='4'
  io500_info_num_data_storage_devices='24'  # if you have 5 data servers, and each has 5 drives, then this number is 25
  io500_info_num_metadata_storage_devices='8'  # if you have 2 metadata servers, and each has 5 drives, then this number is 10
  io500_info_data_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_metadata_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_storage_network='infiniband EDR' # infiniband, omnipath, ethernet, etc
  io500_info_storage_interface='NVMe' # SAS, SATA, NVMe, etc
  # miscellaneous
  io500_info_whatever='infiniband'
}

main
