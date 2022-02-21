#!/bin/bash
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.
# Please also edit 'extra_description' function.

set -euo pipefail  # better error handling

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
io500_run_mdreal="False"  # this one is optional
io500_cleanup_workdir="False"  # this flag is currently ignored. You'll need to clean up your data files manually if you want to.

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
  io500_workdir=/bescratch/user/pllopiss/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=/bescratch/user/pllopiss/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="srun"
  io500_mpiargs="-N 64 -p be-short -t 1-0 --reservation pllopiss_1 -w hpc-be[001-002,006-008,011-014,016-017,019-023,025-026,030-032,035,040-042,045,047,049,051,053-056,059,064,067,072,080,085,087-088,094-096,099,102-104,106-108,112-113,116,120,123-124,126,128-129,134-136,139]"
}

function setup_ior_easy {
  io500_ior_easy_params="-t 16m -b 16m -F -s 1860" # 2M writes, 2 GB per proc, file per proc 
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=33800
}

function setup_ior_hard {
  io500_ior_hard_writes_per_proc=89984
}

function setup_mdt_hard {
  io500_mdtest_hard_files_per_proc=24960
#  io500_mdtest_hard_files_per_proc=100
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
  io500_find_cmd_args=" -r $io500_result_dir/pfind_results"
  
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
  io500_info_system_name='CERN-CEPH-BE'      # e.g. Oakforest-PACS
  io500_info_institute_name='CERN'   # e.g. JCAHPC
  io500_info_storage_age_in_months='3' # not install date but age since last refresh
  io500_info_storage_install_date='10/17'  # MM/YY
  io500_info_filesysem='CephFS'     # e.g. BeeGFS, DataWarp, GPFS, IME, Lustre
  io500_info_filesystem_version='12'
  # client side info
  io500_info_num_client_nodes='142'
  io500_info_procs_per_node='20'
  # server side info
  io500_info_num_metadata_server_nodes='3'
  io500_info_num_data_server_nodes='142'
  io500_info_num_data_storage_devices='426'  # if you have 5 data servers, and each has 5 drives, then this number is 25
  io500_info_num_metadata_storage_devices='xxx'  # if you have 2 metadata servers, and each has 5 drives, then this number is 10
  io500_info_data_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_metadata_storage_type='HDD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_storage_network='ethernet' # infiniband, omnipath, ethernet, etc
  io500_info_storage_interface='SATA' # SAS, SATA, NVMe, etc
  # miscellaneous
  io500_info_whatever='ByteCollider'
}

main
