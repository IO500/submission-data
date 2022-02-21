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
  io500_workdir=/mnt/beegfs/jkiss_BeeGFS/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
  
  
  #create the working directories and set the striping on them
  mkdir -p ${io500_workdir}/ior_easy
  mkdir -p ${io500_workdir}/ior_hard
  mkdir -p ${io500_workdir}/mdt_easy
  mkdir -p ${io500_workdir}/mdt_hard
  # for ior_easy use three OST. ZFS datasets on OSTs were set to 1M recordsize
  /opt/beegfs/sbin/beegfs-ctl --setpattern --numtargets=3 --chunksize=1024k ${io500_workdir}/ior_easy
  # stripe across all 12 ZFS OSTs for ior_hard test, and use 128k chunksize
  /opt/beegfs/sbin/beegfs-ctl --setpattern --numtargets=12 --chunksize=128k ${io500_workdir}/ior_hard
  # for metadata tests use a single OST to reduce overhead, and use 64k chunks
  /opt/beegfs/sbin/beegfs-ctl --setpattern --numtargets=1 --chunksize=64k ${io500_workdir}/mdt_easy
  /opt/beegfs/sbin/beegfs-ctl --setpattern --numtargets=1 --chunksize=64k ${io500_workdir}/mdt_hard
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="mpirun"
  io500_mpiargs="-np 100 -hostfile Hostfile100CPU -mca plm_rsh_no_tree_spawn true"
}

function setup_ior_easy {
  io500_ior_easy_size=23000
  io500_ior_easy_params="-t 2048k -b ${io500_ior_easy_size} -F"
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=170000
}

function setup_ior_hard {
  io500_ior_hard_api="POSIX"
  io500_ior_hard_api_specific_options=""
  io500_ior_hard_writes_per_proc=21000
}

function setup_mdt_hard {
  io500_mdtest_hard_api="POSIX"
  io500_mdtest_hard_api_specific_options=""
  io500_mdtest_hard_files_per_proc=33000
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
  # uses stonewalling, run pfind
  io500_find_cmd_args="-s 1000"

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
  io500_info_system_name='IST Austria HPC'
  io500_info_storage_vendor='"Homemade@IST"'
  io500_info_filesystem_name='"BeeGFS"'
  io500_info_filesystem_type='"BeeGFS"'
  io500_info_filesystem_version='"7.1.3"'
  io500_info_client_nodes='"10"'
  io500_info_client_procs_per_node='"10"'
  io500_info_client_operating_system='"Debian"'
  io500_info_client_operating_system_version='"Debian 9 (stretch)"'
  io500_info_client_kernel_version='"4.9.0-9-amd64"'
  io500_info_md_nodes='"2"'
  io500_info_md_storage_devices='"4"'
  io500_info_md_storage_type='"NVMe Samsung PM1725A 6.4TB"'
  io500_info_md_volatile_memory_capacity='"128GB"'
  io500_info_md_storage_interface='"NVMe"'
  io500_info_md_network='"IB-EDR"'
  io500_info_md_software_version='"EXT4, BeeGFS 7.1.3"'
  io500_info_md_operating_system_version='"Debian 9 (stretch)"'
  io500_info_ds_nodes='"3"'
  io500_info_ds_storage_devices='"132"'
  io500_info_ds_storage_type='"HDD HGST_HUH721010ALE600 10TB 7200RPM"'
  io500_info_ds_volatile_memory_capacity='"128GB"'
  io500_info_ds_storage_interface='"PCI-e 3.0 x8 LSI9300-8e HBA 12Gbps SAS-SATA"'
  io500_info_ds_network='"IB-EDR"'
  io500_info_ds_software_version='"ZFS 0.8.2, BeeGFS 7.1.3"'
  io500_info_ds_operating_system_version='"Debian 9 (stretch)"'
}

main
