#!/bin/bash
#PJM -L rscgrp=ofptest-all
#PJM -L node=2048
#PJM --mpi proc=16384
#PJM -L elapse=2:00:00
#PJM -g gz02
#PJM -j
#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.

set -euo pipefail  # better error handling

#DIR=/cache/xg17i000/x10007/io-500-dev
DIR=$PJM_O_CACHEDIR
export I_MPI_PIN_PROCESSOR_EXCLUDE_LIST=0,68,136,204

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
  io500_workdir=$DIR/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$DIR/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$DIR/bin/ior
  io500_mdtest_cmd=$DIR/bin/mdtest
  io500_mdreal_cmd=$DIR/bin/md-real-io
  io500_mpirun="mpiexec.hydra"
  io500_mpiargs="-n ${PJM_MPI_PROC}"
}

function setup_ior_easy {
  io500_ior_easy_params="-t 2048k -b 16g -F" # 2M writes, 2 GB per proc, file per proc 
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
  io500_mdtest_easy_files_per_proc=650
}

function setup_ior_hard {
  io500_ior_hard_writes_per_proc=300000
}

function setup_mdt_hard {
  io500_mdtest_hard_files_per_proc=40
}

function setup_find {
  #
  # setup the find command. This is an area where innovation is allowed.
  #    There are three default options provided. One is a serial find, one is python
  #    parallel version, one is C parallel version.  Current default is to use serial.
  #    But it is very slow. We recommend to either customize or use the C parallel version.
  #    Instructions below.
  #    If a custom approach is used, please provide enough info so others can reproduce.

  # the serial version that should run (SLOWLY) without modification
  io500_find_mpi="False"
  io500_find_cmd=$DIR/bin/sfind.sh
  io500_find_cmd_args=""

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
  io500_find_cmd="$DIR/bin/pfind"
  io500_find_cmd_args="-s 300 -r $io500_result_dir/pfind_results"
  

  # a parallel version that might require some work, it is a python3 program 
  # if you used utilities/prepare.sh, it should already be there. 
  # change the stonewall to 300 to get a valid score
  #set +u
  #export PYTHONPATH=$PYTHONPATH:$PWD/bin/lib
  #io500_find_mpi="True"
  #io500_find_cmd="$PWD/bin/pfind -stonewall 1"
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

# Add key/value pairs defining your system if you want
# This function needs to exist although it doesn't have to output anything if you don't want
function extra_description {
  echo "System_name='JCAHPC Oakforest-PACS'"
}

main
#rm -rf $io500_workdir
