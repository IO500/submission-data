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
io500_ini="${1}"          # You can set the ini file here
filer=${2:-/mnt/chqlustre1}
num_mounts=${3:-32}
hostfile=${4:-/mnt/scooter/scratchq/systems/scrusan/workspace/projects/lustre/20250522_io500/20250522_b200_hostlist_10n.txt}
ranks=${5:-1600}
io500_mpirun="/mnt/chqlustre1/scratch/scrusan/scratch/software/mvapich/4.0/bin/mpirun"
#io500_mpiargs="-f ${hostfile} -np ${ranks} --map-by node -rmk user /mnt/chqlustre1/scratch/scrusan/scratch/software/src/build/io500-mvapich/io500/singularity.sh ${filer} ${num_mounts} -B /usr -B /usr/bin -B /mnt/shapurefb04_scratcht rockylinux_9.sif"
io500_mpiargs="-bind-to socket -map-by hwthread -f ${hostfile} -np ${ranks} /mnt/chqlustre1/scratch/scrusan/scratch/software/src/build/io500-mvapich/io500/singularity.sh ${filer} ${num_mounts} -B /usr -B /usr/bin -B /mnt/shapurefb04_scratcht rockylinux_9.sif"

function setup(){
  local workdir="$1"
  local resultdir="$2"
  mkdir -p $workdir $resultdir

  local fstype=$(stat -f -c %T ${workdir})
  if [[ "${fstype}" == "lustre" ]];
  then
        local osts=$(lfs df $workdir | grep -c OST)

        # disregard our PFL setup
        #mkdir $workdir/ior-easy
        #lfs setstripe -c 1 $workdir/ior-easy

        # overstriping for ior-hard
        mkdir $workdir/ior-hard
        lfs setstripe -C ${osts} $workdir/ior-hard

        # DNE1 for mdtest-easy
        # we are not getting good balance w/ DNE3 right now when
        # using singularity. i do not quite understand
        mkdir $workdir/mdtest-easy
        lfs setdirstripe -c -1 -D $workdir/mdtest-easy

        # DNE2 for mdtest-hard
        mkdir $workdir/mdtest-hard
        lfs setdirstripe -c -1 -D $workdir/mdtest-hard
  fi

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
