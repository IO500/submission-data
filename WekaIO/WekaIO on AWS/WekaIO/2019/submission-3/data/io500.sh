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
  io500_mpiargs="--oversubscribe -n 8625 -H 172.31.56.151,172.31.63.221,172.31.52.62,172.31.63.191,172.31.59.91,172.31.55.87,172.31.60.195,172.31.63.193,172.31.55.181,172.31.51.51,172.31.62.208,172.31.60.175,172.31.54.110,172.31.57.115,172.31.61.239,172.31.50.188,172.31.63.46,172.31.61.123,172.31.57.67,172.31.60.113,172.31.50.192,172.31.60.241,172.31.50.69,172.31.62.245,172.31.50.66,172.31.61.71,172.31.50.243,172.31.58.249,172.31.48.205,172.31.63.59,172.31.57.144,172.31.60.30,172.31.59.178,172.31.54.144,172.31.63.185,172.31.53.53,172.31.62.178,172.31.52.13,172.31.59.27,172.31.58.18,172.31.60.144,172.31.53.87,172.31.63.95,172.31.60.236,172.31.56.245,172.31.53.171,172.31.56.30,172.31.60.106,172.31.50.48,172.31.58.167,172.31.60.77,172.31.51.6,172.31.54.36,172.31.63.111,172.31.52.135,172.31.58.186,172.31.51.190,172.31.62.61,172.31.50.249,172.31.62.180,172.31.49.10,172.31.63.67,172.31.55.170,172.31.51.60,172.31.51.100,172.31.54.101,172.31.54.252,172.31.49.46,172.31.55.131,172.31.49.224,172.31.62.136,172.31.58.204,172.31.60.219,172.31.54.46,172.31.57.117,172.31.54.254,172.31.55.252,172.31.63.74,172.31.56.89,172.31.59.169,172.31.55.168,172.31.51.96,172.31.48.81,172.31.55.172,172.31.54.169,172.31.52.85,172.31.56.160,172.31.53.135,172.31.49.210,172.31.63.64,172.31.60.174,172.31.50.227,172.31.59.246,172.31.48.251,172.31.55.212,172.31.49.109,172.31.58.2,172.31.63.234,172.31.63.169,172.31.56.6,172.31.62.124,172.31.54.8,172.31.49.88,172.31.60.207,172.31.63.86,172.31.53.64,172.31.50.22,172.31.58.1,172.31.51.242,172.31.53.183,172.31.52.28,172.31.60.167,172.31.57.90,172.31.59.50,172.31.49.75,172.31.60.215,172.31.51.25,172.31.63.201,172.31.58.40,172.31.57.93,172.31.55.7,172.31.61.40,172.31.61.179,172.31.60.9,172.31.54.77,172.31.50.79,172.31.53.121,172.31.57.224,172.31.50.212,172.31.54.13,172.31.58.212,172.31.60.163,172.31.53.240,172.31.62.182,172.31.63.184,172.31.51.129,172.31.49.137,172.31.51.176,172.31.53.140,172.31.53.190,172.31.56.185,172.31.58.142,172.31.53.182,172.31.60.142,172.31.61.31,172.31.57.186,172.31.48.138,172.31.57.19,172.31.56.161,172.31.50.120,172.31.57.175,172.31.49.138,172.31.55.161,172.31.62.93,172.31.54.245,172.31.56.235,172.31.49.158,172.31.57.151,172.31.48.200,172.31.58.145,172.31.50.118,172.31.60.166,172.31.60.108,172.31.57.139,172.31.51.132,172.31.53.96,172.31.58.119,172.31.59.102,172.31.62.173,172.31.62.162,172.31.52.206,172.31.50.152,172.31.48.129,172.31.57.131,172.31.50.217,172.31.55.56,172.31.53.157,172.31.58.61,172.31.59.16,172.31.59.153,172.31.60.150,172.31.58.29,172.31.49.128,172.31.54.163,172.31.60.116,172.31.50.230,172.31.60.171,172.31.53.36,172.31.50.94,172.31.55.255,172.31.61.158,172.31.52.160,172.31.51.238,172.31.53.147,172.31.52.219,172.31.57.59,172.31.52.182,172.31.62.27,172.31.52.132,172.31.58.54,172.31.54.161,172.31.53.235,172.31.61.195,172.31.61.169,172.31.53.11,172.31.59.1,172.31.59.65,172.31.59.55,172.31.53.238,172.31.60.73,172.31.55.84,172.31.53.161,172.31.53.15,172.31.51.75,172.31.62.218,172.31.63.6,172.31.59.38,172.31.59.8,172.31.51.211,172.31.48.36,172.31.48.5,172.31.58.85,172.31.51.58,172.31.54.78,172.31.59.37,172.31.58.72,172.31.56.126,172.31.54.50,172.31.50.4,172.31.49.223,172.31.62.65,172.31.53.232,172.31.56.65,172.31.61.208,172.31.50.34,172.31.55.254,172.31.55.224,172.31.60.229,172.31.58.196,172.31.57.62,172.31.52.240,172.31.58.193,172.31.56.250,172.31.60.228,172.31.52.252,172.31.58.219,172.31.58.255,172.31.57.68,172.31.61.87,172.31.49.213,172.31.59.245,172.31.52.200,172.31.48.239,172.31.48.224,172.31.59.248,172.31.60.248,172.31.54.206,172.31.63.239,172.31.50.247,172.31.56.81,172.31.63.89,172.31.52.7,172.31.60.162,172.31.55.3,172.31.48.6,172.31.52.6,172.31.57.26,172.31.60.187,172.31.51.29,172.31.61.186,172.31.57.86,172.31.63.48,172.31.60.26,172.31.55.135,172.31.59.95,172.31.62.72,172.31.63.147,172.31.51.18,172.31.51.82,172.31.63.164,172.31.48.178,172.31.48.19,172.31.63.112,172.31.56.115,172.31.60.222,172.31.61.213,172.31.53.56,172.31.63.22,172.31.57.21,172.31.49.45,172.31.61.74,172.31.62.172,172.31.48.222,172.31.61.109,172.31.54.96,172.31.49.172,172.31.60.12,172.31.61.89,172.31.51.31,172.31.60.90,172.31.51.7,172.31.62.190,172.31.56.176,172.31.60.160,172.31.58.162,172.31.61.10,172.31.63.222,172.31.55.61,172.31.56.45,172.31.58.185,172.31.54.174,172.31.54.150,172.31.57.146,172.31.59.87,172.31.52.5,172.31.52.35,172.31.56.90,172.31.51.126,172.31.57.138,172.31.48.137,172.31.63.37,172.31.57.58,172.31.48.59,172.31.61.167,172.31.60.97,172.31.51.159,172.31.50.87,172.31.49.23,172.31.55.221,172.31.48.42,172.31.53.164,172.31.57.88,172.31.55.151,172.31.63.139,172.31.59.107,172.31.62.28,172.31.54.30,172.31.59.52,172.31.55.223,172.31.48.82,172.31.51.30,172.31.55.41,172.31.55.165,172.31.49.39,172.31.48.38 --mca pml ob1 --mca btl self,tcp"
}

function setup_ior_easy {
  io500_ior_easy_params="--posix.odirect -u -t 2048k"
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
}

function setup_ior_hard {
  io500_ior_hard_api="POSIX"
  io500_ior_hard_api_specific_options="--posix.odirect"
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
  io500_find_cmd_args="-s $io500_stonewall_timer -M 1000 -q 50000 -r $io500_result_dir/pfind_results"

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
  io500_info_storage_install_date="2019-11-08"
  io500_info_storage_vendor="WekaIO"
  io500_info_filesystem_name="WekaIO"
  io500_info_filesystem_type="WekaIO Matrix"
  io500_info_filesystem_version="3.5"
  io500_info_client_nodes="345"
  io500_info_client_procs_per_node="25"
  io500_info_client_operating_system="Amazon Linux"
  io500_info_client_operating_system_version="AMI release 2017.09"
  io500_info_client_kernel_version="4.9.51-10.52.amzn1.x86_64"
  io500_info_md_nodes="120"
  io500_info_md_storage_devices="8"
  io500_info_md_storage_type="NVMe"
  io500_info_md_volatile_memory_capacity="768.0 GiB"
  io500_info_md_storage_interface="NVMe"
  io500_info_md_network="Ethernet"
  io500_info_md_software_version="3.5"
  io500_info_md_operating_system_version="Amazon Linux AMI release 2017.09"
  io500_info_md_overhead="12.5"
  io500_info_ds_nodes="120"
  io500_info_ds_storage_devices="960"
  io500_info_ds_storage_type="NVMe"
  io500_info_ds_volatile_memory_capacity="768.0 GiB"
  io500_info_ds_storage_interface="NVMe"
  io500_info_ds_network="Ethernet"
  io500_info_ds_software_version="3.5"
  io500_info_ds_operating_system_version="Amazon Linux AMI release 2017.09"
  io500_info_ds_overhead="12.5"
  io500_info_whatever="This was run on Amazon Web Services (AWS). We modified pfind to implement a FIFO for the pending work instead of a stack, broke a single large directory to multiple work items and made some changes to the stealing policy."
  io500_info_comment="We do not have a notion of a traditional metadata server architecture. Our metadata is distributed evenly across all storage nodes."
}

main
