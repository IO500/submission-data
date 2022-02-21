#!/bin/bash
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.
# Please also edit 'extra_description' function.

set -euo pipefail  # better error handling

PROGRAM="${0##*/}"

function usage () {
  echo
  cat <<-_EOF
  Usage:
    $PROGRAM work_dir results_dir [ io500_dir ]
      where 'work_dir' is the place where the benchmark IO will take place
      and 'results_dir' is where the output results will be kept. The
      optional 'io500_dir' is where the io500 directory is (containing
      the pre-built IOR and mdtest binaries

_EOF
}

if [[ $# -ne 3 ]]; then
  usage
  exit 0
fi

JOB_WORK_DIR="$1"
JOB_RESULTS_DIR="$2"
IO500_DIR="${3:-$HOME/projects/benchmarking/io-500-src}"

if [ ! -d "$JOB_RESULTS_DIR" ] ; then
  echo "JOB_RESULTS_DIR: $JOB_RESULTS_DIR does not exist"
  exit 1
fi

if [ ! -d "$JOB_WORK_DIR" ] ; then
  echo "JOB_WORK_DIR: $JOB_WORK_DIR does not exist"
  mkdir -pv $JOB_WORK_DIR
fi
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
  io500_workdir=$JOB_WORK_DIR                       # directory where the data will be stored
  io500_result_dir=$JOB_RESULTS_DIR                 # the directory where the output results will be kept
  timestamp=`date +%Y.%m.%d-%H.%M.%S`           # create a uniquifier

  io500_ior_easy=$io500_workdir/ior_easy
  io500_ior_hard=$io500_workdir/ior_hard
  io500_mdt_easy=$io500_workdir/mdt_easy
  io500_mdt_hard=$io500_workdir/mdt_hard

  mkdir -p $io500_workdir $io500_result_dir $io500_ior_easy $io500_ior_hard $io500_mdt_easy $io500_mdt_hard

  # Use DNE1 remote directories for mdt_easy
  mdtest_easy_testdir="$io500_mdt_easy/test-dir.0-0"
  lfs mkdir -c -1 "$mdtest_easy_testdir"
  # Use DoM for mdt_easy
  lfs setstripe -L mdt -E 1M "$mdtest_easy_testdir"

  ## Use DNE2 striped directories for mdt_easy
  #lfs setdirstripe -c -1 -D $io500_mdt_easy
  ## Use DoM for mdt_easy
  #lfs setstripe -L mdt -E 1M "$io500_mdt_easy"

  # 2 stripes, 16M stripe-size
  lfs setstripe -c 2 -S 16M $io500_ior_easy

  # Use Lustre OST overstriping
  lfs setstripe -C $((288*4)) -S 16M $io500_ior_hard

  # Use DNE2 striped directory for mdt_hard
  lfs setdirstripe -c -1 -D $io500_mdt_hard
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$IO500_DIR/bin/ior
  io500_mdtest_cmd=$IO500_DIR/bin/mdtest
  io500_mdreal_cmd=$IO500_DIR/bin/md-real-io
  io500_mpirun="srun"
  io500_mpiargs="--mpi=pmi2"
}

function setup_ior_easy {
  io500_ior_easy_params="-a=POSIX --posix.odirect -t 16m"
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
}

function setup_ior_hard {
  io500_ior_hard_api="MPIIO"
  io500_ior_hard_api_specific_options=""
}

function setup_mdt_hard {
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
  #io500_find_cmd=$IO500_DIR/bin/sfind.sh
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
  io500_find_mpi="False"
  #io500_find_cmd="mpirun -ppn 1 $IO500_DIR/bin/pfind"
  io500_find_cmd="srun --mpi=pmi2 --ntasks-per-node 1 --ntasks $NUM_NODES $IO500_DIR/bin/pfind"
  # uses stonewalling, run pfind
  #io500_find_cmd_args=""
  io500_find_cmd_args="-N -P -r $io500_result_dir/pfind_results"

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
  source $IO500_DIR/utilities/io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.$timestamp.txt
}

# Information fields; these provide information about your system hardware
# Use https://vi4io.org/io500-info-creator/ to generate information about your hardware
# that you want to include publicly!
function extra_description {
  io500_info_system_name='Cambridge-DAC'      # e.g. Oakforest-PACS
  io500_info_institute_name='University of Cambridge RCS'   # e.g. JCAHPC
  io500_info_storage_age_in_months='18' # not install date but age since last refresh
  io500_info_storage_install_date='05/18'  # MM/YY
  io500_info_filesystem='Lustre'     # e.g. BeeGFS, DataWarp, GPFS, IME, Lustre
  io500_info_filesystem_version='2.13 (tip of master branch as of running)'
  io500_info_filesystem_vendor='Dell EMC'
  # client side info
  io500_info_num_client_nodes='32'
  io500_info_procs_per_node='32'
  # server side info
  io500_info_num_metadata_server_nodes='24'
  io500_info_num_data_server_nodes='24'
  io500_info_num_data_storage_devices='288'  # if you have 5 data servers, and each has 5 drives, then this number is 25
  io500_info_num_metadata_storage_devices='24'  # if you have 2 metadata servers, and each has 5 drives, then this number is 10
  io500_info_data_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_metadata_storage_type='SSD' # HDD, SSD, persistent memory, etc, feel free to put specific models
  io500_info_storage_network='omnipath' # infiniband, omnipath, ethernet, etc
  io500_info_storage_interface='NVMe' # SAS, SATA, NVMe, etc
  # miscellaneous
  io500_info_whatever="More details on the architecture were presented at LAD'19: https://www.eofs.eu/_media/events/lad19/03_matt_raso-barnett-io500-cambridge.pdf"
}

main
