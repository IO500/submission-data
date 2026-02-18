#!/bin/bash
#SBATCH --job-name=IO500
#SBATCH --nodes=728
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=1
#SBATCH --exclusive

export LD_LIBRARY_PATH=$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# CXI optimization
export FI_CXI_RX_MATCH_MODE=software 
export FI_CXI_RDZV_PROTO=alt_read

# MPI-IO hints
export MPICH_VERSION_DISPLAY=1
export MPICH_ENV_DISPLAY=1
#export MPICH_RANK_REORDER_DISPLAY=1
export MPICH_MPIIO_STATS=0
export MPICH_OFI_NIC_POLICY=NUMA
export MPICH_MPIIO_AGGREGATOR_PLACEMENT_DISPLAY=1
export MPICH_MPIIO_HINTS_DISPLAY=1
export MPICH_MPIIO_AGGREGATOR_PLACEMENT_STRIDE=1
export MPICH_MPIIO_HINTS="*:cray_cb_write_lock_mode=0:romio_no_indep_rw=false:romio_ds_write=disable:romio_cb_read=disable"

# INSTRUCTIONS:
#
# The only parts of the script that may need to be modified are:
#  - setup() to configure the binary locations and MPI parameters
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.

# This script takes its parameters from the same .ini file as io500 binary.
io500_ini="$1"          # You can set the ini file here
io500_mpirun="srun"
io500_mpiargs="-N 2080 -n 16640 --ntasks-per-node=8"

function setup(){
  local workdir="$1"
  local resultdir="$2"
  mkdir -p $workdir $resultdir

  # IOR EASY
  mkdir -p $workdir/ior-easy
  lfs setstripe -c 1 -i -1 -p bandwidth -S 1M $workdir/ior-easy

  # IOR HARD
  mkdir -p $workdir/ior-hard
  #lfs setstripe -p bandwidth -C 208 -S 1M $workdir/ior-hard
  lfs setstripe -p bw_32ssu -C 128 -S 1M $workdir/ior-hard

  # MDTEST EASY
  #lfs mkdir -c 1 -i 0 $workdir/mdtest-easy
  mkdir -p $workdir/mdtest-easy
  lfs setdirstripe -c 16 -i -1 $workdir/mdtest-easy/test-dir.0-0
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-easy/test-dir.0-0
  lfs setstripe -c 1 -S 1M -p iops_bw $workdir/mdtest-easy/test-dir.0-0

  # MDTEST HARD
  lfs mkdir -c 16 -i -1 $workdir/mdtest-hard
  lfs setdirstripe -D -c 16 -i -1 --max-inherit 3 $workdir/mdtest-hard
  lfs setstripe -c 1 -S 1M -p iops_bw $workdir/mdtest-hard
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
