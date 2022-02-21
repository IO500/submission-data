#!/bin/bash
#SBATCH --nodes=10 --ntasks-per-node=6 -p compute -A ku0598

# INSTRUCTIONS:
#
# The only parts of the script that may need to be modified are:
#  - setup() to configure the binary locations and MPI parameters
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.
io500_ini="$1"          # You can set the ini file here
io500_mpirun="mpiexec"
export DD_STDERR=err 
export DAOS_FUSE=/daos/u2
export DAOS_POOL=e9cd968a-137f-4332-b23e-2d6f87cdd911
export DAOS_CONT=77235465-b362-48f2-be5e-bc0726595be1
export CRT_TIMEOUT=120

#io500_mpiargs="-np 216 --allow-run-as-root -host aep01:36,aep02:36,aep03:36,aep04:36,aep05:36,aep07:36,aep08:36,aep09:36,aep10:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE --mca bl_tcp_if_include ib0"
#io500_mpiargs="-np 9RT_TIMEOUT
#io500_mpiargs="-np 96 --allow-run-as-root -host aep02:36,aep03:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE --mca bl_tcp_if_include ib0"
#io500_mpiargs="-np 216 --allow-run-as-root -host aep01:36,aep02:36,aep03:36,aep04:36,aep07:36,aep08:36,aep09:36,aep10:36,9200A:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE --mca bl_tcp_if_include ib0"
#io500_mpiargs="-np 120 --allow-run-as-root -host aep01:36,aep02:36,aep03:36,aep04:36,aep05:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE --mca bl_tcp_if_include ib0"
#io500_mpiargs="-np 360 --map-by node --allow-run-as-root -host aep01:36,aep02:36,aep03:36,aep04:36,aep05:36,aep06:36,9200A:36,9200B:36,9200C:36,9200D:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE -x DD_STDERR"
io500_mpiargs="-np 360 --map-by node --allow-run-as-root --host aep01:36,aep02:36,aep03:36,aep04:36,aep05:36,aep06:36,9200A:36,9200B:36,9200C:36,9200D:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE -x DD_STDERR -x CRT_TIMEOUT"
#io500_mpiargs="-np 192 --allow-run-as-root -host aep01:36,aep02:36,aep03:36,aep04:36 -x DAOS_POOL -x DAOS_CONT -x DAOS_FUSE"

function setup(){
  local workdir="$1"
  local resultdir="$2"
  mkdir -p $workdir $resultdir

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
