#!/bin/bash
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.
# Please also edit 'extra_description' function.

#set -euo pipefail  # better error handling

export LD_LIBRARY_PATH=/vol7/io500_20190930/mvapich2-new/lib/:$LD_LIBRARY_PATH

function usage(){
  cat << EOF
  Usage: 
    $0 node-number nodename tasks-per-node
EOF
  exit 0
}

[ $# -eq 2 ] || usage

# turn these to True successively while you debug and tune this benchmark.
# for each one that you turn to true, go and edit the appropriate function.
# to find the function name, see the 'main' function.
# These are listed in the order that they run.

io500_run_ior_easy="True"
io500_run_md_easy="True"
io500_run_ior_hard="True"
io500_run_md_hard="True"
io500_run_find="True"
io500_run_ior_easy_read="True"
io500_run_md_easy_stat="True"
io500_run_ior_hard_read="True"
io500_run_md_hard_stat="True"
io500_run_md_hard_read="True"
io500_run_md_easy_delete="True" # turn this off if you want to just run find by itself
io500_run_md_hard_delete="True" # turn this off if you want to just run find by itself
io500_run_mdreal="False"  # this one is optional
io500_cleanup_workdir="False"  # this flag is currently ignored. You'll need to clean up your data files manually if you want to.
io500_clean_cache="False"
io500_stonewall_timer=300 # Stonewalling timer, stop with wearout after 300s with default test, set to 0, if you never want to abort...
io500_rules="regular"

# to run this benchmark, find and edit each of these functions.
# please also edit 'extra_description' function to help us collect the required data.
function main {
  setup_directories
  setup_paths $1 $2
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
  io500_workdir=$PWD/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept

  io500_ior_easy_dir=${io500_workdir}/ior_easy
  io500_ior_hard_dir=${io500_workdir}/ior_hard
  io500_mdt_easy_dir=${io500_workdir}/mdt_easy
  io500_mdt_hard_dir=${io500_workdir}/mdt_hard

  mkdir -p ${io500_workdir} ${io500_result_dir} ${io500_ior_easy_dir} ${io500_ior_hard_dir} ${io500_mdt_easy_dir} ${io500_mdt_hard_dir}

#ior hard
  lfs setstripe -c 572 -S 8M ${io500_ior_hard_dir}
#DNE1 for mdtset easy
  lfs mkdir -c 40 "$io500_mdt_easy_dir/#test-dir.0-0"
#Use DoM for mdt_easy
  lfs setstripe -L mdt -E 64K "$io500_mdt_easy_dir/#test-dir.0-0"

#Use DNE2 striped directory for mdt_hard
  lfs setdirstripe -c 40 -D $io500_mdt_hard_dir
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="yhrun"
  io500_mpiargs="-w $1 --ntasks-per-node $2"
}

function setup_ior_easy {
  # io500_ior_easy_size is the amount of data written per rank in MiB units,
  # but it can be any number as long as it is somehow used to scale the IOR
  # runtime as part of io500_ior_easy_params
  io500_ior_easy_size=40
  # 2M writes, 2 GB per proc, file per proc
  io500_ior_easy_params="-a=POSIX --posix.odirect -t 1m -C -b ${io500_ior_easy_size}g -F"
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=67000
}

function setup_ior_hard {
  io500_ior_hard_api="MPIIO"
  io500_ior_hard_api_specific_options="-U /vol7/io500_20190930/mpio -H"
  io500_ior_hard_writes_per_proc=52800
}

function setup_mdt_hard {
  io500_mdtest_hard_api="POSIX"
  io500_mdtest_hard_api_specific_options=""
  io500_mdtest_hard_files_per_proc=38888
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
  io500_find_mpi="False"
  io500_find_cmd="yhrun -N 200 -n 400 $PWD/bin/pfind"
  io500_find_cmd_args="-N -P -s $io500_stonewall_timer -r $io500_result_dir/pfind_results >$io500_result_dir/find.txt 2>&1"


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

  # for GPFS systems, you should probably use the provided mmfind wrapper
  # if you used ./utilities/prepare.sh, you'll find this wrapper in ./bin/mmfind.sh
  #io500_find_mpi="False"
  #io500_find_cmd="$PWD/bin/mmfind.sh"
  #io500_find_cmd_args=""
}

function setup_mdreal {
  echo -n ""
}

function run_benchmarks {
  # Important: source the io500_fixed.sh script.  Do not change it. If you discover
  # a need to change it, please email the mailing list to discuss
  source ./utilities/io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.$timestamp.txt
}

# Add key/value pairs defining your system
# Feel free to add extra ones if you'd like
function extra_description {
  # top level info
  io500_info_system_name='Tianhe-2E'      # e.g. Oakforest-PACS
  io500_info_institute_name='National Supercomputing Center in Changsha'   # e.g. JCAHPC
  io500_info_storage_age_in_months='3' # not install date but age since last refresh
  io500_info_storage_install_date='08/2019'  # MM/YY
  io500_info_filesystem='Lustre'     # e.g. BeeGFS, DataWarp, GPFS, IME, Lustre
  io500_info_filesystem_version='2.12.2'
  io500_info_filesystem_vendor='National University of Defense Technology'
  # client side info
  io500_info_num_client_nodes='480'
  io500_info_procs_per_node='11'
  # server side info
  io500_info_num_metadata_server_nodes='40'
  io500_info_num_data_server_nodes='52'
  io500_info_num_data_storage_devices='572'  # if you have 5 data servers, and each has 5 drives, then this number is 25
  io500_info_num_metadata_storage_devices='40'  # if you have 2 metadata servers, and each has 5 drives, then this number is 10
  io500_info_data_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_metadata_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_storage_network='omnipath' # infiniband, omnipath, ethernet, etc
  io500_info_storage_interface='NVMe' # SAS, SATA, NVMe, etc
}
main $1 $2
