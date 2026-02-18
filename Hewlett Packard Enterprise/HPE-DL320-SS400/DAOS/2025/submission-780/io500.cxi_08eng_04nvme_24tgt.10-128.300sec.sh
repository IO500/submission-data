#!/bin/bash
#
#SBATCH --job-name=daos_io500
#SBATCH --output=log.io500_dfs_rf2.cxi_08eng_04nvme_24tgt.10-128.300sec.%J
#SBATCH  --error=log.io500_dfs_rf2.cxi_08eng_04nvme_24tgt.10-128.300sec.%J
#
#SBATCH --nodes=10
#SBATCH --tasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#
#SBATCH --licenses=daos
#SBATCH --reservation=daos-testing
# SBATCH --nodelist="x8003c1s7b0n3"
#
#SBATCH --partition=cluster
#SBATCH --exclusive
# SBATCH --account=pr27ca
#
#SBATCH --time=4:00:00

#export IO500_MODE="--mode=extended"
#export IO500_MODE="--mode=standard"
export IO500_MODE=" "

export SLEEP_SEC=300

export DAOS_POOL="cpe-pool"
export DAOS_CONT="hennecke_rf0_e1MiB"
export DAOS_MOUNT="/tmp/${DAOS_POOL}/${DAOS_CONT}"

export NODES=10
export TPN=128
export RANKS=1280

#export JOBID="$$"
export JOBID="$SLURM_JOB_ID"

echo
echo `date`
echo
echo "HPE job configuration:"
echo "* Jobid : $JOBID"
echo "* Nodes : $NODES"
echo "* TPN   : $TPN"
echo "* Ranks : $RANKS"
echo

echo
echo "HPE MPI configuration:"

#echo module load mpi/openmpi-x86_64
#     module load mpi/openmpi-x86_64

module list

echo
echo "HPE MPI configuration:"
#which $CC
#which $CXX
#which $MPI_CC
#which $MPI_CXX
which cc
which mpicc

#export OMPI_ALLOW_RUN_AS_ROOT=1
#export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

echo
echo "DAOS configuration (cxi_08eng_04nvme_24tgt):"
echo "* `daos version` (`rpm -qa daos`)"
echo "* `rpm -qa libfabric`"
echo "* DAOS_POOL=$DAOS_POOL"
echo "* DAOS_CONT=$DAOS_CONT"
echo "* DAOS_MOUNT=$DAOS_MOUNT"
echo "* daos system query:"
daos system query
echo
echo sleep 10
     sleep 10
#echo
#echo daos fs check $DAOS_POOL $DAOS_CONT --flags=print
#     daos fs check $DAOS_POOL $DAOS_CONT --flags=print
#echo
#echo sleep 10
#     sleep 10
echo
echo "=== querying container to check if it exists"
date
daos cont query $DAOS_POOL $DAOS_CONT
retVal0=$?
if [ $retVal0 -ne 0 ]; then
  echo "=== cont query failed with rc=$retVal0, maybe does not exist?"
else
  date
  echo daos cont destroy $DAOS_POOL $DAOS_CONT
       daos cont destroy $DAOS_POOL $DAOS_CONT
  retVal1=$?
  date
  if [ $retVal1 -ne 0 ]; then
    echo "!!! cont destroy failed with rc=$retVal1, sleep 5 and retrying"
    sleep 5
    daos cont destroy $DAOS_POOL $DAOS_CONT
    retVal2=$?
    if [ $retVal2 -ne 0 ]; then
      echo "!!! second destroy also failed, rc=$retVal2; exiting"
      exit
    fi
  fi
  date
fi
echo "=== end of container destroy sequence"
echo
echo sleep 10
     sleep 10
#echo
#echo daos fs check $DAOS_POOL $DAOS_CONT --flags=print
#     daos fs check $DAOS_POOL $DAOS_CONT --flags=print
#echo sleep 10
#     sleep 10

#echo daos cont create --type POSIX --properties=rd_fac:0 --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#     daos cont create --type POSIX --properties=rd_fac:0 --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#echo daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:256kiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#     daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:256kiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#echo daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:512kiB --chunk-size=2MiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#     daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:512kiB --chunk-size=2MiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
echo daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:1MiB --chunk-size=4MiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
     daos cont create --type POSIX --properties=rd_fac:0,ec_cell_sz:1MiB --chunk-size=4MiB --file-oclass=S1     --dir-oclass=SX     $DAOS_POOL $DAOS_CONT
#echo daos cont create --type POSIX --properties=rd_fac:2,ec_cell_sz:256kiB --file-oclass=RP_3G1     --dir-oclass=RP_3GX     $DAOS_POOL $DAOS_CONT
#     daos cont create --type POSIX --properties=rd_fac:2,ec_cell_sz:256kiB --file-oclass=RP_3G1     --dir-oclass=RP_3GX     $DAOS_POOL $DAOS_CONT
sleep 10
echo "* daos cont query $DAOS_POOL $DAOS_CONT:"
daos cont query $DAOS_POOL $DAOS_CONT
echo "* daos cont get-prop $DAOS_POOL $DAOS_CONT:"
daos cont get-prop $DAOS_POOL $DAOS_CONT
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

MPI_BIND_TO=""
MPI_BIND_TO="--bind-to socket --map-by socket --npernode 128"
MPI_BIND_TO="--bind-to socket "

mv "$1" "$1.$JOBID"
io500_ini="$1.$JOBID" # You can set the ini file here

#io500_mpirun="mpiexec"
#io500_mpiargs="-np 2"

#io500_mpirun="mpirun -n 1280 $MPI_BIND_TO -genvall -genv D_POOL_WARMUP 1 -genv DAOS_POOL $DAOS_POOL -genv DAOS_CONT $DAOS_CONT -genv DAOS_PREFIX $DAOS_MOUNT"

io500_mpiargs=""

function setup(){
  local workdir="$1"
  local resultdir="$2"

  # OpenMPI version:
# io500_mpirun="mpirun --hostfile machinefile.$NODES -np 1280 $MPI_BIND_TO -x D_POOL_WARMUP=1 -x DAOS_POOL=$DAOS_POOL -x DAOS_CONT=$DAOS_CONT -x DAOS_PREFIX=$workdir "
# io500_mpirun="mpirun  -x HCOLL_MAIN_IB=hsn0 --mca btl_tcp_if_include bond0 --mca btl tcp,vader,self -x PATH -x LD_LIBRARY_PATH --hostfile machinefile.$NODES -np 1280 $MPI_BIND_TO -x D_POOL_WARMUP=1 -x DAOS_POOL=$DAOS_POOL -x DAOS_CONT=$DAOS_CONT -x DAOS_PREFIX=$workdir "
# io500_mpirun="mpirun --mca mtl ^cxi,ofi --mca btl tcp,self --mca oob tcp -mca coll_hcoll_enable 0 --mca pml ob1 -x PATH -x LD_LIBRARY_PATH --hostfile machinefile.$NODES -np 1280 $MPI_BIND_TO -x D_POOL_WARMUP=1 -x DAOS_POOL=$DAOS_POOL -x DAOS_CONT=$DAOS_CONT -x DAOS_PREFIX=$workdir "
# io500_mpirun="mpirun --mca coll_hcoll_enable 0 -x PATH -x LD_LIBRARY_PATH --hostfile machinefile.$NODES -np 1280 $MPI_BIND_TO -x D_POOL_WARMUP=1 -x DAOS_POOL=$DAOS_POOL -x DAOS_CONT=$DAOS_CONT -x DAOS_PREFIX=$workdir "
# io500_mpirun="mpirun --mca mtl ^cxi,ofi --mca btl tcp,self --mca btl_tcp_if_include bond0 --mca oob tcp -mca coll_hcoll_enable 0 --mca pml ob1 -x PATH -x LD_LIBRARY_PATH --hostfile machinefile.$NODES -np 1280 $MPI_BIND_TO -x D_POOL_WARMUP=1 -x DAOS_POOL=$DAOS_POOL -x DAOS_CONT=$DAOS_CONT -x DAOS_PREFIX=$workdir "

  # expand Slurm nodelist (which may contain wildcards/ranges) into hostfile
  nodelist=$(scontrol show hostname $SLURM_NODELIST)
  printf "%s\n" "${nodelist[@]}" > machinefile.$JOBID

  # Callisto with vanilla mpich interactively:
# io500_mpirun="mpirun -f machinefile.$JOBID -n 1280 $MPI_BIND_TO -genvall -genv D_POOL_WARMUP 1 -genv DAOS_POOL $DAOS_POOL -genv DAOS_CONT $DAOS_CONT -genv DAOS_PREFIX $workdir "
# io500_mpirun="mpirun -f machinefile.$JOBID -n 1280 $MPI_BIND_TO -genvall -genv D_POOL_WARMUP 1 -genv LD_PRELOAD /usr/lib64/libpil4dfs.so "

  # Callisto with Slurm and CPE srun:
  export D_POOL_WARMUP=1
  export DAOS_PREFIX="$workdir"

# export HG_LOG_LEVEL="warn"
# export HG_LOG_SUBSYS="hg,na,libfabric"

  io500_mpirun="srun -u"

# #this will not work as the container is not mounted...
# echo "mkdir -p $workdir (datadir)"
# mkdir -p $workdir

  echo "mkdir -p $resultdir (resultdir)"
  mkdir -p $resultdir
  echo "mkdir done (`date`)"
  S=30
  S=$SLEEP_SEC
  echo "sleeping $S sec ... "
  sleep $S
# echo "sleeping $S sec ... "
# sleep $S
# echo "sleeping $S sec ... "
# sleep $S
# echo "finished sleeping"
# echo

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
cat ${io500_ini}.tmp | sed "s/@STONEWALL/300/g; s/@NPROC/$SLURM_NTASKS/g; s/@DAOS_POOL/$DAOS_POOL/g; s/@DAOS_CONT/$DAOS_CONT/g; s##$DAOS_MOUNT#g" > ${io500_ini}
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
# echo "$io500_mpirun $io500_mpiargs /home/users/hennecke/io500-sc25-mpich/io500 $io500_ini $IO500_MODE --timestamp $timestamp"
#       $io500_mpirun $io500_mpiargs /home/users/hennecke/io500-sc25-mpich/io500 $io500_ini $IO500_MODE --timestamp $timestamp
  echo "$io500_mpirun $io500_mpiargs /home/users/hennecke/io500-sc25-cpe/io500 $io500_ini $IO500_MODE --timestamp $timestamp"
  set -x
        $io500_mpirun $io500_mpiargs /home/users/hennecke/io500-sc25-cpe/io500 $io500_ini $IO500_MODE --timestamp $timestamp
  set +x
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
echo "querying pool=$DAOS_POOL:"
echo
daos -j pool query $DAOS_POOL
echo
echo "querying cont=$DAOS_CONT:"
echo
daos -j cont query $DAOS_POOL $DAOS_CONT
echo
SLEEP_SEC=30
echo "sleeping $SLEEP_SEC seconds before returning ..."
sleep $SLEEP_SEC
echo "sleeping $SLEEP_SEC seconds before returning ..."
sleep $SLEEP_SEC
echo
echo `date`
echo

