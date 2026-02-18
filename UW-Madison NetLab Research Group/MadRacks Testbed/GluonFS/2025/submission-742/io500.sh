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
#io500_ini="$1"          # You can set the ini file here
#io500_mpirun="mpiexec"
#io500_mpiargs="-np 1"
export PATH=/usr/bin:$PATH
export LD_LIBRARY_PATH=/usr/lib:/usr/lib64:$LD_LIBRARY_PATH

numa_cpus="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15"
#numa_cpus="16,22,23,24,25,26,27,28,29,30,31"
io500_ini="$1" 
io500_mpirun="mpiexec"                                                                                                
#io500_mpiargs="-np 120 -hostfile mpihosts.txt --mca plm_rsh_no_tree_spawn 1 --mca btl_tcp_if_include 10.101.0.0/24 -cpu-set $numa_cpus -x LD_PRELOAD=librfdsdfs.so"
io500_mpiargs="-np 620 -hostfile mpihosts.txt --mca plm_rsh_no_tree_spawn 1 --mca btl_tcp_if_include 10.101.0.0/24 -cpu-set $numa_cpus"
#io500_mpiargs="-np 50 -hostfile mpihosts.txt --mca plm_rsh_no_tree_spawn 1 --mca btl_tcp_if_include 10.101.0.0/24 -x LD_PRELOAD=librfdsdfs.so"

function setup(){
  local workdir="$1"
  local resultdir="$2"
  mkdir -p $workdir $resultdir

	hosts=($(awk '{print $1}' mpihosts.txt))
    #hosts=("10.101.0.21" "10.101.0.22" "10.101.0.1")
    #hosts=()

  io500_path='/home/omidr/io500/'
  for host in "${hosts[@]}"; do
      #echo "Copying to $host"
      scp "/home/omidr/rfds/build/librfdsdfs.so" "$host:/home/omidr/rfds/build/" > /dev/null 2>&1
      ssh omidr@$host 'cd /home/omidr/rfds; make fslib_install;' > /dev/null 2>&1
      scp "$io500_ini" "$host:$io500_path" > /dev/null 2>&1

      # Remove shared mems
      #ssh omidr@$host 'rm -f /dev/shm/sem.shared_sem'
      #ssh omidr@$host 'ipcrm -M 0x1234 || true'
  done

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
