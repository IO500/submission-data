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
io500_clean_cache="False" # attempt to clean the cache after every benchmark, useful for validating the performance results and for testing with a local node; it uses the io500_clean_cache_cmd (can be overwritten); make sure the user can write to /proc/sys/vm/drop_caches
io500_stonewall_timer=300 # Stonewalling timer, set to 300 to be an official run
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
  io500_workdir=$PWD/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="mpirun"
  io500_mpiargs="--allow-run-as-root --oversubscribe -n 2616 -H 10.0.11.64,10.0.8.63,10.0.4.65,10.0.4.68,10.0.11.65,10.0.11.69,10.0.6.66,10.0.9.68,10.0.11.67,10.0.2.64,10.0.11.68,10.0.3.62,10.0.6.61,10.0.11.66,10.0.8.69,10.0.6.65,10.0.9.62,10.0.9.65,10.0.6.70,10.0.6.60,10.0.3.69,10.0.6.64,10.0.4.61,10.0.4.66,10.0.8.67,10.0.6.62,10.0.7.62,10.0.10.61,10.0.7.63,10.0.10.64,10.0.7.69,10.0.7.64,10.0.7.70,10.0.3.68,10.0.3.61,10.0.9.66,10.0.10.65,10.0.11.62,10.0.3.67,10.0.8.61,10.0.9.61,10.0.2.69,10.0.7.60,10.0.2.63,10.0.3.64,10.0.10.63,10.0.7.61,10.0.3.70,10.0.1.63,10.0.11.63,10.0.1.68,10.0.2.68,10.0.2.67,10.0.2.61,10.0.6.63,10.0.1.62,10.0.9.64,10.0.8.70,10.0.7.65,10.0.1.60,10.0.4.63,10.0.2.66,10.0.3.65,10.0.10.68,10.0.10.70,10.0.10.62,10.0.4.60,10.0.2.62,10.0.1.64,10.0.4.62,10.0.9.70,10.0.8.68,10.0.3.60,10.0.4.67,10.0.8.66,10.0.2.60,10.0.9.63,10.0.8.62,10.0.3.66,10.0.6.68,10.0.11.70,10.0.9.60,10.0.11.60,10.0.8.65,10.0.6.69,10.0.11.61,10.0.10.67,10.0.6.67,10.0.3.63,10.0.4.70,10.0.10.60,10.0.8.64,10.0.1.69,10.0.9.67,10.0.8.60,10.0.4.64,10.0.2.70,10.0.9.69,10.0.10.66,10.0.7.66,10.0.2.65,10.0.1.67,10.0.7.68,10.0.7.67,10.0.1.65,10.0.4.69,10.0.10.69,10.0.1.66,10.0.1.61 --mca pml ob1 --mca btl self,tcp --mca btl_tcp_if_include 10.0.0.0/16 --mca routed direct"
}

function setup_ior_easy {
  io500_ior_easy_size="11000"
  io500_ior_easy_params="--posix.odirect -u -t 1024k "
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_files_per_proc="90000"
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
}

function setup_ior_hard {
  io500_ior_hard_writes_per_proc="80000"
  io500_ior_hard_api="POSIX"
  io500_ior_hard_api_specific_options="--posix.odirect"
}

function setup_mdt_hard {
  io500_mdtest_hard_files_per_proc="70000"
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
  io500_find_mpi="False"
  io500_find_cmd="/mnt/weka/io-500-dev/bin/custom_pfind.sh"
  # uses stonewalling, run pfind
  io500_find_cmd_args="-s $io500_stonewall_timer -q 50000 -r $io500_result_dir/pfind_results"

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

# Information fields; these provide information about your system hardware
# Use https://vi4io.org/io500-info-creator/ to generate information about your hardware
# that you want to include publicly!
function extra_description {
  # TODO: Please add your information using the info-creator!
  # EXAMPLE:
  io500_info_system_name="WekaIO"      # e.g. Oakforest-PACS
  io500_info_submitter="Alexander Howard"
  io500_info_institution="WekaIO"
  io500_info_system="WekaIO"
  io500_info_system_classification="production"
  io500_info_storage_install_date="2019-11-11"
  io500_info_storage_vendor="WekaIO"
  io500_info_filesystem_name="WekaIO"
  io500_info_filesystem_type="WekaIO Matrix"
  io500_info_filesystem_version="3.5"
  io500_info_client_nodes="10"
  io500_info_client_procs_per_node="261"
  io500_info_client_operating_system="CentOS"
  io500_info_client_operating_system_version="7.6.1810"
  io500_info_client_kernel_version="3.10.0-957.el7.x86_64"
  io500_info_md_nodes="26"
  io500_info_md_storage_devices="6"
  io500_info_md_storage_type="NVMe"
  io500_info_md_volatile_memory_capacity="352.0 GB"
  io500_info_md_storage_interface="NVMe"
  io500_info_md_network="Infiniband HDR"
  io500_info_md_software_version="3.5"
  io500_info_md_operating_system_version="CentOS 7.6.1810"
  io500_info_md_overhead="12.5"
  io500_info_ds_nodes="26"
  io500_info_ds_storage_devices="156"
  io500_info_ds_storage_type="NVMe"
  io500_info_ds_volatile_memory_capacity="352.0 GB"
  io500_info_ds_storage_interface="NVMe"
  io500_info_ds_network="Infiniband HDR"
  io500_info_ds_software_version="3.5"
  io500_info_ds_operating_system_version="CentOS 7.6.1810"
  io500_info_ds_overhead="12.5"
  io500_info_whatever="We modified pfind to implement a FIFO for the pending work instead of a stack, broke a single large directory to multiple work items and made some changes to the stealing policy."
  io500_info_comment="We do not have a notion of a traditional metadata server architecture. Our metadata is distributed evenly across all storage nodes."
}

main
