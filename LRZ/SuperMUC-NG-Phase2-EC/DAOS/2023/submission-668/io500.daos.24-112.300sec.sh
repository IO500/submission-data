#!/bin/bash
#
########################################################################
#
# Intel "Florence" Slurm script for DAOS benchmarks on the IB fabric
#
########################################################################
#
#SBATCH        --job-name=d5_DFS
#SBATCH          --output=log.io500_dfs.daos.24-112.300sec.%J
#SBATCH           --error=log.io500_dfs.daos.24-112.300sec.%J
#SBATCH       --partition=all
#SBATCH       --exclusive
#SBATCH      --no-requeue
#SBATCH        --licenses=daos:10
# BATCH        --nodelist="compute[21-22]"
# BATCH        --nodelist="compute[21]"
# BATCH     --reservation=DAOS
#SBATCH           --nodes=24
#SBATCH --ntasks-per-node=112
#SBATCH   --cpus-per-task=1
#SBATCH          --ntasks=2688
#SBATCH            --time=4:00:00

#export LD_PRELOAD="/usr/lib64/libioil.so"

export PATH="${HOME}/mpich-4.1.1-ucx/bin:$PATH"

export IO500_MODE="--mode=extended"
export IO500_MODE=""

export FANOUT=16

export SLEEP_SEC=300


export DAOS_HOSTLIST="lrz-sng-phase2"
export DAOS_FUSE="/daos/${USER}"
export DAOS_POOL="m02r01s01ib1" ; export DAOS_CONT="cont01" ; export MACHINE="machinefile.r02"
export DAOS_POOL="lrz_32srv" ; export DAOS_CONT="cont01" ; export MACHINE="machinefile.r01"
export DAOS_POOL="lrz_18srv" ; export DAOS_CONT="cont01" ; export MACHINE="machinefile.24cli"

export D_LOG_FILE="/tmp/daos.$USER.log"

export TPN=112
export MACH="${MACHINE}-$TPN"
envsubst '$TPN' < $MACHINE > ${MACH}

echo
echo `date`
echo
echo "LRZ DAOS configuration (daos):"
echo "* `daos version` (`rpm -qa daos`)"
echo "* `rpm -qa libfabric` " # provider:`grep "GetAttachInfo Provider" /tmp/daos.$USER.log|tail -1|cut -d: -f5-`"
echo "* DAOS_HOSTLIST=$DAOS_HOSTLIST"
echo "* DAOS_POOL=$DAOS_POOL"
echo "* DAOS_CONT=$DAOS_CONT"
echo "* DAOS_FUSE=$DAOS_FUSE"
echo
#echo "pdsh -f $FANOUT -w $SLURM_JOB_NODELIST -N \"dfuse $DAOS_FUSE $DAOS_POOL $DAOS_CONT\""
#      pdsh -f $FANOUT -w $SLURM_JOB_NODELIST -N  "dfuse $DAOS_FUSE $DAOS_POOL $DAOS_CONT"
#echo
echo "LRZ MPI configuration:"
echo
mpichversion


export FI_OFI_RXM_USE_SRX=1
export FI_VERBS_PREFER_XRC=1
#export FI_LOG_LEVEL="warn"
#export D_LOG_STDERR_IN_LOG=1

echo "------------------------------------------------------------"
echo
set | grep -E "^SLURM|^OFI|^FI_|^OMPI|^CRT|^LD_|^D_" | sort
echo
echo "------------------------------------------------------------"


########################################################################

# INSTRUCTIONS:
#
# The only parts of the script that may need to be modified are:
#  - setup() to configure the binary locations and MPI parameters
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.

# This script takes its parameters from the same .ini file as io500 binary.

MPI_BIND_TO="core"
MPI_BIND_TO="hwthread"
MPI_BIND_TO="none"
MPI_BIND_TO="ib0"
MPI_BIND_TO="socket"

mv "$1" "$1.$$"
io500_ini="$1.$$"          # You can set the ini file here

#io500_mpirun="mpiexec"
#io500_mpiargs="-np 2"
io500_mpirun="mpirun -f $MACH -n 2688 --bind-to $MPI_BIND_TO -genvall -genv DAOS_POOL $DAOS_POOL -genv DAOS_CONT $DAOS_CONT "
io500_mpiargs=""

function setup(){
  #local workdir="$1"
# local workdir="$DAOS_FUSE/$1"
  local resultdir="$2"
# echo "mkdir -p $workdir $resultdir" # writing to datadir=/ to avoid needing a dfuse mount...
  mkdir -p $workdir $resultdir
  echo "mkdir done (`date`)"
  S=$SLEEP_SEC
  S=30
  echo -n "sleeping $S sec ... "
  sleep $S
  echo " finished sleeping"
  echo

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

# MH::add DAOS container info (created in Slurm Prolog) to the ini template
mv ${io500_ini} ${io500_ini}.tmp
cat ${io500_ini}.tmp | sed "s/@STONEWALL/300/g; s/@NPROC/$SLURM_NTASKS/g; s/@DAOS_POOL/$DAOS_POOL/g; s/@DAOS_CONT/$DAOS_CONT/g; s#@DAOS_FUSE#$DAOS_FUSE#g" > ${io500_ini}
rm ${io500_ini}.tmp

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
  echo "$io500_mpirun $io500_mpiargs $HOME/io500-leap154-isc23-mpich411/io500 $io500_ini $IO500_MODE --timestamp $timestamp"
        $io500_mpirun $io500_mpiargs $HOME/io500-leap154-isc23-mpich411/io500 $io500_ini $IO500_MODE --timestamp $timestamp
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

# MH::epilog - unmount, query pool, and allow time to quiece
#echo
#echo "pdsh -f $FANOUT -w $SLURM_JOB_NODELIST -N \"fusermount3 -u $DAOS_FUSE\""
#      pdsh -f $FANOUT -w $SLURM_JOB_NODELIST -N  "fusermount3 -u $DAOS_FUSE"
echo
echo `date`
echo
echo "querying DAOS_POOL:"
echo
daos -j pool query $DAOS_POOL
echo
echo "sleeping $SLEEP_SEC seconds before returning ..."
sleep $SLEEP_SEC
echo
echo `date`
echo

