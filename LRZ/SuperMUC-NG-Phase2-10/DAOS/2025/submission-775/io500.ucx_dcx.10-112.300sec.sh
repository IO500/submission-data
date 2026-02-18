#!/bin/bash
#
########################################################################
#
# LRZ Slurm script for DAOS benchmarks on the IB fabric
#
########################################################################
#
#SBATCH        --job-name=d5_dfs
#SBATCH          --output=log.io500_dfs_rf0.ucx_dcx.10-112.300sec.%J
#SBATCH           --error=log.io500_dfs_rf0.ucx_dcx.10-112.300sec.%J
# SBATCH       --partition=all
#SBATCH       --exclusive
#SBATCH      --no-requeue
#SBATCH --licenses=daos:1
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=112
#SBATCH --ntasks-per-core=1
#SBATCH --ntasks=1120
#
# SBATCH --reservation=DAOS
#
# SBATCH --partition=large
#SBATCH --partition=general
# SBATCH --partition=tmp0
# SBATCH --qos=nolimit
#
#SBATCH --account=pr27ca
#SBATCH --exclusive
#SBATCH --time=4:00:00

#export IO500_MODE="--mode=standard"

export SLEEP_SEC=300

export DAOS_POOL="${USER}_pool01"
export DAOS_CONT="cont_rf0_e128kiB"
export DAOS_MOUNT="/tmp/${DAOS_POOL}/${DAOS_CONT}"

export NODES=10
export TPN=112
export RANKS=1120

#echo "module unload stack/24.1.0"
#      module unload stack/24.1.0
#echo "module switch spack spack/24.1.1"
#      module switch spack spack/24.1.1
#echo "module load intel-toolkit/2025.0.1"
#      module load intel-toolkit/2025.0.1

echo "module unload stack/24.1.0"
      module unload stack/24.1.0
echo "module load stack/24.5.0"
      module load stack/24.5.0
echo "module load intel-toolkit/2025.1.0"
      module load intel-toolkit/2025.1.0
      module list

unset UCX_HANDLE_ERRORS

export I_MPI_OFFLOAD=0 # prevent GPU issues to affect this CPU-only job

echo
echo `date`
echo
echo "LRZ job configuration:"
echo "* Jobid : $SLURM_JOB_ID"
echo "* Nodes : $NODES"
echo "* TPN   : $TPN"
echo "* Ranks : $RANKS"
echo
echo "LRZ MPI configuration:"
which $CC
which $CXX
which $MPI_CC
which $MPI_CXX
echo
echo "LRZ DAOS configuration (ucx_dcx):"
echo "* `daos version` (`rpm -qa daos`)"
echo "* `ofed_info -s`"
echo "* DAOS_POOL=$DAOS_POOL"
echo "* DAOS_CONT=$DAOS_CONT"
echo "* DAOS_MOUNT=$DAOS_MOUNT"
#echo "* daos system query:"
#daos system query
#echo "* daos cont query $DAOS_POOL $DAOS_CONT:"
#daos cont query $DAOS_POOL $DAOS_CONT
echo
df

echo "------------------------------------------------------------"
echo
set | grep -E "^SLURM|^OFI|^FI_|^UCX|^OMPI|^I_MPI|^MPI|^CRT|^LD_|^D_|^HG" | sort
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

MPI_BIND_TO="--bind-to socket"
MPI_BIND_TO=""

mv "$1" "$1.$$"
io500_ini="$1.$$"          # You can set the ini file here

#io500_mpirun="mpiexec"
#io500_mpiargs="-np 2"

#io500_mpirun="mpirun -n 1120 $MPI_BIND_TO -genvall -genv D_POOL_WARMUP 1 -genv DAOS_POOL $DAOS_POOL -genv DAOS_CONT $DAOS_CONT -genv DAOS_PREFIX $DAOS_MOUNT"

io500_mpiargs=""

function setup(){
  local workdir="$1"
  local resultdir="$2"

  io500_mpirun="mpirun -n 1120 $MPI_BIND_TO -genvall -genv D_POOL_WARMUP 1 -genv DAOS_POOL $DAOS_POOL -genv DAOS_CONT $DAOS_CONT -genv DAOS_PREFIX $workdir"

# #this will not work as the container is not mounted...
# echo "mkdir -p $workdir (datadir)"
# mkdir -p $workdir

  echo "mkdir -p $resultdir (resultdir)"
  mkdir -p $resultdir
  echo "mkdir done (`date`)"
  S=$SLEEP_SEC
  S=10
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

# MH::add job and DAOS container infos to the ini template
mv ${io500_ini} ${io500_ini}.tmp
cat ${io500_ini}.tmp | sed "s/@STONEWALL/300/g; s/@NPROC/$SLURM_NTASKS/g; s/@DAOS_POOL/$DAOS_POOL/g; s/@DAOS_CONT/$DAOS_CONT/g; s#/tmp/di49puz3_pool01/cont_rf0_e128kiB#$DAOS_MOUNT#g" > ${io500_ini}
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
  echo "$io500_mpirun $io500_mpiargs    $HOME/io500-isc25-impi/io500 $io500_ini $IO500_MODE --timestamp $timestamp"
        $io500_mpirun $io500_mpiargs    $HOME/io500-isc25-impi/io500 $io500_ini $IO500_MODE --timestamp $timestamp
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

# MH::epilog - query pool, and allow time to quiece
echo
echo `date`
echo
#echo "querying DAOS_POOL:"
#echo
#daos -j pool query $DAOS_POOL
#echo
#echo "querying DAOS_CONT:"
#echo
#daos -j cont query $DAOS_POOL $DAOS_CONT
#echo
#SLEEP_SEC=3600
echo "sleeping $SLEEP_SEC seconds before returning ..."
sleep $SLEEP_SEC
echo "sleeping $SLEEP_SEC seconds before returning ..."
sleep $SLEEP_SEC
echo
echo `date`
echo

