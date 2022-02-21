#!/bin/bash
#SBATCH --nodes=10 --ntasks-per-node=6 -p compute -A ku0598

# INSTRUCTIONS:
#
# The only parts of the script that may need to be modified are:
#  - setup() to configure the binary locations and MPI parameters
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.

export LD_LIBRARY_PATH=/home/bpfs/lib/:/home/bpfs/:${LD_LIBRARY_PATH}
export BPFS_CONFIG=/home/bpfs/BPFS.json
export LD_PRELOAD=/home/bpfs/libbpfsfe.so
export UCX_NET_DEVICES=all
export UCX_TLS=rc
#export UCX_NET_DEVICES=mlx5_0:1,mlx5_1:1,mlx5_2:1
export UCX_RC_MLX5_TRAFFIC_CLASS=162
export MOUNT_ENV_FSID=bpfs1
export UCX_RNDV_THRESH=64k
export UCX_ZCOPY_THRESH=16k
#export UCX_MAX_RNDV_RAILS=1
#export UCX_LOG_LEVEL=FATAL
#export UCX_RC_MLX5_TM_ENABLE=y
#export UCX_DC_MLX5_TM_ENABLE=y

# This script takes its parameters from the same .ini file as io500 binary.
io500_ini="$1"          # You can set the ini file here
io500_mpirun="mpiexec"
#io500_mpiargs="--allow-run-as-root --oversubscribe --host 10.223.20.139,10.223.20.140,10.223.20.141 -np 96 \
#io500_mpiargs="--allow-run-as-root --oversubscribe -np 32 "
io500_mpiargs="--allow-run-as-root --oversubscribe --hostfile 10_client -np 800 \
      -x LD_LIBRARY_PATH=/home/bpfs/:/home/bpfs/lib/:${LD_LIBRARY_PATH} \
      -x BPFS_CONFIG=/home/bpfs/BPFS.json \
      -x LD_PRELOAD=/home/bpfs/libbpfsfe.so \
      -x UCX_NET_DEVICES=all \
      -x UCX_TLS=rc \
      -x UCX_ZCOPY_THRESH=16k \
      -x UCX_RNDV_THRESH=64k \
      -x UCX_RC_MLX5_TRAFFIC_CLASS=162" 
      #-x UCX_LOG_LEVEL=FATAL \
      #-x UCX_NET_DEVICES=mlx5_0:1,mlx5_1:1,mlx5_2:1 \
      #-x UCX_MAX_RNDV_RAILS=1 \

function setup(){
  local workdir="$1"
  local resultdir="$2"
  #export LD_PRELOAD=""
  #mkdir -p $workdir $resultdir
  #export LD_PRELOAD=/home/bpfs/syscall_test/libsyscall.so
  # Example commands to create output directories for Lustre.  Creating
  # top-level directories is allowed, but not the whole directory tree.
  #if (( $(lfs df $workdir | grep -c MDT) > 1 )); then
  #  lfs setdirstripe -D -c -1 $workdir
  #fi
  #lfs setstripe -c 1 $workdir
  #mkdir $workdir/ior-easy $workdir/ior-hard
  #mkdir $workdir/mdtest-easy $workdir/mdtest-hard
  #local osts=$(lfs df $workdir | grep -c OST)
  # Try overstriping for ior-hard to improve scaling, or use wide striping
  #lfs setstripe -C $((osts * 4)) $workdir/ior-hard ||
  #  lfs setstripe -c -1 $workdir/ior-hard
  # Try to use DoM if available, otherwise use default for small files
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-easy || true #DoM?
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-hard || true #DoM?
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-rnd
}

# *****  YOU SHOULD NOT EDIT ANYTHING BELOW THIS LINE  *****
set -eo pipefail  # better error handling

if [[ -z "$io500_ini" ]]; then
  echo "error: ini file must be specified.  usage: $0 <config.ini>"
  exit 1
fi
if [[ ! -s "$io500_ini" ]]; then
  echo "error: ini file '$io500_ini' not found or empty"
  exit 2
fi

function get_ini_section_param() {
  local section="$1"
  local param="$2"
  local inside=false

  while read LINE; do
    LINE=$(sed -e 's/ *#.*//' -e '1s/ *= */=/' <<<$LINE)
    $inside && [[ "$LINE" =~ "[.*]" ]] && inside=false && break
    [[ -n "$section" && "$LINE" =~ "[$section]" ]] && inside=true && continue
    ! $inside && continue
    #echo $LINE | awk -F = "/^$param/ { print \$2 }"
    if [[ $(echo $LINE | grep "^$param *=" ) != "" ]] ; then
      # echo "$section : $param : $inside : $LINE" >> parsed.txt # debugging
      echo $LINE | sed -e "s/[^=]*=[ \t]*\(.*\)/\1/"
      return
    fi
  done < $io500_ini
  echo ""
}

function get_ini_global_param() {
  local param="$1"
  local default="$2"
  local val

  val=$(get_ini_section_param global $param |
  	sed -e 's/[Ff][Aa][Ll][Ss][Ee]/False/' -e 's/[Tt][Rr][Uu][Ee]/True/')

  echo "${val:-$default}"
}

function run_benchmarks {
  $io500_mpirun $io500_mpiargs $PWD/io500 $io500_ini --timestamp $timestamp
}

create_tarball() {
  local sourcedir=$(dirname $io500_resultdir)
  local fname=$(basename ${io500_resultdir})
  local tarball=$sourcedir/io500-$HOSTNAME-$fname.tgz

  cp -v $0 $io500_ini $io500_resultdir
  tar czf $tarball -C $sourcedir $fname
  echo "Created result tarball $tarball"
}

function main {
  # These commands extract the 'datadir' and 'resultdir' from .ini file
  timestamp=$(date +%Y.%m.%d-%H.%M.%S)           # create a uniquifier
  [ $(get_ini_global_param timestamp-datadir True) != "False" ] &&
    ts="$timestamp" || ts="io500"
  # working directory where the test files will be created
  export io500_workdir=$(get_ini_global_param datadir $PWD/datafiles)/$ts
  [ $(get_ini_global_param timestamp-resultdir True) != "False" ] &&
    ts="$timestamp" || ts="io500"
  # the directory where the output results will be kept
  export io500_resultdir=$(get_ini_global_param resultdir $PWD/results)/$ts

  setup $io500_workdir $io500_resultdir
  run_benchmarks

  if [[ ! -s "system-information.txt" ]]; then
    echo "Warning: please create a 'system-information.txt' description by"
    echo "copying the information from https://vi4io.org/io500-info-creator/"
  else
    cp "system-information.txt" $io500_resultdir
  fi

  create_tarball
}

main
