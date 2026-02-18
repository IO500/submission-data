#!/bin/bash
#SBATCH --nodes=10 --ntasks-per-node=6 -p compute -A ku0598

# INSTRUCTIONS:
#
# The only parts of the script that may need to be modified are:
#  - setup() to configure the binary locations and MPI parameters
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.

# This script takes its parameters from the same .ini file as io500 binary.
io500_ini="$1"          # You can set the ini file here
io500_mpirun="mpiexec"
#io500_mpiargs="-np 2"
#io500_mpiargs="-np 30 --host c1:3,c2:3,c3:3,c4:3,c5:3,c6:3,c7:3,c8:3,c9:3,c10:3 -mca pml ucx --map-by node -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 80 --host c1:8,c2:8,c3:8,c4:8,c5:8,c6:8,c7:8,c8:8,c9:8,c10:8 -mca pml ucx  --map-by node  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 120 --host c1:12,c2:12,c3:12,c4:12,c5:12,c6:12,c7:12,c8:12,c9:12,c10:12 -mca pml ucx  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 180 --host c1:18,c2:18,c3:18,c4:18,c5:18,c6:18,c7:18,c8:18,c9:18,c10:18 -mca pml ucx  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 130 --host c1:13,c2:13,c3:13,c4:13,c5:13,c6:13,c7:13,c8:13,c9:13,c10:13 -mca pml ucx  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 150 --host c1:15,c2:15,c3:15,c4:15,c5:15,c6:15,c7:15,c8:15,c9:15,c10:15 -mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 200 --host c1:20,c2:20,c3:20,c4:20,c5:20,c6:20,c7:20,c8:20,c9:20,c10:20 -mca pml ucx --map-by node -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 100 --host c1:10,c2:10,c3:10,c4:10,c5:10,c6:10,c7:10,c8:10,c9:10,c10:10 -mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1"
io500_mpiargs="-np 320 --host c1:32,c2:32,c3:32,c4:32,c5:32,c6:32,c7:32,c8:32,c9:32,c10:32 -mca pml ucx --map-by node -x UCX_NET_DEVICES=mlx5_0:1"

#io500_mpiargs="-np 108 --host c1:12,c3:12,c4:12,c5:12,c6:12,c7:12,c8:12,c9:12,c10:12 -mca pml ucx  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 162 --host c1:18,c2:18,c3:18,c4:18,c5:18,c6:18,c8:18,c9:18,c10:18 -mca pml ucx  -x UCX_NET_DEVICES=mlx5_0:1"
#io500_mpiargs="-np 180 --host c1:20,c2:20,c3:20,c4:20,c5:20,c6:20,c8:20,c9:20,c10:20 -mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1"

function setup(){
  local workdir="$1"
  local resultdir="$2"
  mkdir -p $workdir $resultdir

  # Example commands to create output directories for Lustre.  Creating
  # top-level directories is allowed, but not the whole directory tree.
  #if (( $(lfs df $workdir | grep -c MDT) > 1 )); then
  #  lfs setdirstripe -D -c -1 $workdir
  #fi
  local osts=$(lfs df $workdir | grep -c OST)
  lfs setstripe -c $osts $workdir 
  mkdir -p $workdir/ior-easy $workdir/ior-hard
  mkdir -p $workdir/mdtest-easy $workdir/mdtest-hard
  #local osts=$(lfs df $workdir | grep -c OST)
  # Try overstriping for ior-hard to improve scaling, or use wide striping
  #lfs setstripe -C $((osts * 4)) $workdir/ior-hard ||
  #  lfs setstripe -c -1 $workdir/ior-hard
  # Try to use DoM if available, otherwise use default for small files
  lfs setstripe -E 64k -L mdt $workdir/mdtest-easy # || true #DoM?
  lfs setstripe -E 64k -L mdt $workdir/mdtest-hard # || true #DoM?
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
