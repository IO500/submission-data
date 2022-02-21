#!/bin/bash
#PBS -A NBB
#PBS -q gpu
#PBS -b 78
#PBS -T openmpi
#PBS -v NQSV_MPI_VER=gdr/4.0.3/gcc8.3.1-cuda11.2.1
#PBS -l elapstim_req=03:00:00
#
# INSTRUCTIONS:
# This script takes its parameters from the same .ini file as io500 binary.
#
# The only parts of the script that may need to be modified are:
#  - setup_paths() to configure the binary locations and MPI parameters
#  - setup_directories() to create/tune the IOR/mdtest output directories
#
# Please visit https://vi4io.org/io500-info-creator/ to help generate the
# "system-information.txt" file, by pasting the output of the info-creator.
# This file contains details of your system hardware for your submission.

module load openmpi/$NQSV_MPI_VER

. /work/NBB/tatebe/spack/share/spack/setup-env.sh
spack load mochi-margo

cd $PBS_O_WORKDIR

PREFIX=/work/NBB/tatebe/local
BINDIR=$PREFIX/bin
export PATH=$BINDIR:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
TMPDIR=/scr/tatebe
MDIR=/tmp/gfarm-tatebe
LOGD=$PBS_O_WORKDIR/log
mkdir -p $LOGD

THOST=host-$$
CHOST=chost-$$
MPIHOST=mpihost-$$

n=10

nnodes=$(wc -l $PBS_NODEFILE | awk '{ print $1 }')

tail -n $((nnodes - n)) $PBS_NODEFILE > $THOST
head -n $n $PBS_NODEFILE > $CHOST
head -n $n $NQSII_MPINODES > $MPIHOST

chfsctl -h $CHOST -m $MDIR stop > /dev/null 2>&1
chfsctl -h $CHOST -m $MDIR kill > /dev/null 2>&1

eval `chfsctl -p verbs -h $THOST -C 0 -c $TMPDIR -L $LOGD start`
[ X"$CHFS_SERVER" = X ] && exit 0
VID=$(chlist | awk '{ print $2 }' | sh ./ch.sh)
[ X"$VID" = X ] && exit 0
chfsctl -h $THOST stop
CHFS_SERVER=

eval `chfsctl -p verbs -h $THOST -C 0 -c $TMPDIR -N $VID -O "-T 10" -L $LOGD start`
[ X"$CHFS_SERVER" = X ] && exit 0
timeout=20
while [ $timeout -gt 0 -a $(chlist | wc -l) -lt $((nnodes - n)) ]; do
	timeout=$((timeout - 1))
	sleep 1
done
chmkdir $MDIR > /dev/null 2>&1 || :
for h in $(cat $CHOST); do
	ssh $h mkdir -p "$MDIR"
	ssh $h LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\" PATH=\"$PATH\" CHFS_SERVER=\"$CHFS_SERVER\" CHFS_LOG_PRIORITY=$CHFS_LOG_PRIORITY CHFS_CHUNK_SIZE=$CHFS_CHUNK_SIZE CHFS_RDMA_THRESH=$CHFS_RDMA_THRESH CHFS_RPC_TIMEOUT_MSEC=$CHFS_RPC_TIMEOUT_MSEC CHFS_NODE_LIST_CACHE_TIMEOUT=$CHFS_NODE_LIST_CACHE_TIMEOUT chfuse -o direct_io,modules=subdir,subdir="$MDIR" "$MDIR"
done

chfsctl -h $THOST status

# Set the paths to the binaries and how to launch MPI jobs.
# If you ran ./prepare.sh successfully, then binaries are in ./bin/
function setup_paths {
  io500_ior_cmd=$BINDIR/ior
  io500_mdtest_cmd=$BINDIR/mdtest
  io500_mpirun="mpirun"
  io500_mpiargs="--leave-session-attached -hostfile $MPIHOST -x CHFS_SERVER -x PATH -x LD_LIBRARY_PATH --map-by node"
}

# Set directories where benchmark files are created and where the results go.
# If you want to set up stripe tuning on your output directories or anything
# similar, then this is the right place to do it.
function setup_directories {
  local workdir
  local resultdir
  local ts

  mkdir -p $io500_workdir $io500_resultdir

  # Example commands to create output directories for Lustre.  Creating
  # top-level directories is allowed, but not the whole directory tree.
  #if (( $(lfs df $io500_workdir | grep -c MDT) > 1 )); then
  #  lfs setdirstripe -D -c -1 $io500_workdir
  #fi
  #lfs setstripe -c 1 $io500_workdir
  #mkdir $io500_workdir/ior-easy $io500_workdir/ior-hard
  #mkdir $io500_workdir/mdtest-easy $io500_workdir/mdtest-hard
  #local osts=$(lfs df $io500_workdir | grep -c OST)
  # Try overstriping for ior-hard to improve scaling, or use wide striping
  #lfs setstripe -C $((osts * 4)) $io500_workdir/ior-hard ||
  #  lfs setstripe -c -1 $io500_workdir/ior-hard
  # Try to use DoM if available, otherwise use default for small files
  #lfs setstripe -E 64k -L mdt $io500_workdir/mdtest-easy || true #DoM?
  #lfs setstripe -E 64k -L mdt $io500_workdir/mdtest-hard || true #DoM?
}

# *****  YOU SHOULD NOT EDIT ANYTHING BELOW THIS LINE  *****
set -eo pipefail  # better error handling

#io500_ini="${1:-""}"
io500_ini=config-chfs.ini
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

  setup_directories
  setup_paths
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

for h in $(cat $CHOST); do
	ssh $h fusermount -u "$MDIR"
done
chfsctl -h $THOST stop
rm -f $THOST $CHOST $MPIHOST
