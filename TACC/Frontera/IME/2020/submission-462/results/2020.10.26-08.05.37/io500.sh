#!/bin/bash
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

# Set the paths to the binaries and how to launch MPI jobs.
# If you ran ./prepare.sh successfully, then binaries are in ./bin/
function setup_paths {
  ##CNODES="flash-32,flash-33,flash-34,flash-35,flash-36,flash-37,flash-38,flash-39,flash-40,flash-41"
  CNODES="flash-42,flash-43,flash-44,flash-45,flash-47,flash-48,flash-50,flash-51,flash-52,flash-53"
  #CNODES="flash-32,flash-33,flash-37,flash-38,flash-44,flash-45,flash-50,flash-51,flash-56,flash-57"
  #CNODES="flash-32,flash-37,flash-40,flash-41,flash-42,flash-45,flash-47,flash-48,flash-63"
#BINDING="-genv MV2_CPU_MAPPING 0,28:14,42:1,29:15,43:2,30:16,44:3,31:17,45:4,32:18,46:5,33:19,47:6,34:20,48:7,35:21,49:8,36:22,50:9,37:23,51:10,38:24,52:11,39:25,53:12,40:26,54:13,41:27,55"
#BINDING="-genv MV2_CPU_MAPPING 0,28:1,29:2,30:3,31:4,32:5,33:6,34:7,35:8,36:9,37:10,38:11,39:12,40:13,41:14,42:15,43:16,44:17,45:18,46:19,47:20,48:21,49:22,50:23,51:24,52:25,53:26,54:27,55"
#BINDING="-genv MV2_CPU_MAPPING 0:28:1:29:2:30:3:31:4:32:5:33:6:34:7:35:8:36:9:37:10:38:11:39:12:40:13:41:14:42:15:43:16:44:17:45:18:46:19:47:20:48:21:49:22:50:23:51:24:52:25:53:26:54:27:55"
BINDING="-genv MV2_CPU_MAPPING 0:1:14:15:2:3:16:17:4:5:18:19:6:7:20:21:8:9:22:23:10:11:24:25:12:13:26:27"
#BINDING="-genv MV2_CPU_MAPPING 0,28:1,29:2,30:3,31:4,32:5,33:6,34:7,35:8,36:9,37:10,38:11,39:12,40:13,41"
#BINDING="-genv MV2_CPU_MAPPING 0,28,14,42,1,29,15,43,2,30,16,44,3,31,17,45,4,32,18,46,5,33,19,47,6,34,20,48,7,35,21,49,8,36,22,50,9,37,23,51,10,38,24,52,11,39,25,53,12,40,26,54,13,41,27,55"
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mpirun="/opt/ddn/mvapich/bin/mpirun"
  #io500_mpiargs="-np 110 -ppn 11 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_NUM_HCAS 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_BFS_PATH /scratch2/flash -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so"
  #io500_mpiargs="-np 280 -ppn 28 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_NUM_HCAS 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so"
  #io500_mpiargs="-np 120 -ppn 12 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so"
  #io500_mpiargs="-np 280 -ppn 28 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_BFS_PATH /scratch2/flash -genv IM_CLIENT_ENABLE_SGL 1 -genv IM_CLIENT_NO_MKNOD_CREATE 1 -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so"
#w/o mmd
#io500_mpiargs="-np 280 -ppn 28 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 "
#mmd
#io500_mpiargs="-ppn 14 -np 140 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 --hosts $CNODES  -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 -env IM_CLIENT_NET_IF ib0-verbs  $PWD/io500 $io500_ini --timestamp $timestamp : -np 140 -env IM_CLIENT_NET_IF ib1-verbs "
#taskset
io500_mpiargs="-np 140 -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so -genv IM_CLIENT_BFS_PATH /scratch2/flash/ -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 --hosts $CNODES  -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 -env IM_CLIENT_NET_IF ib0-verbs   taskset -c 0-13 $PWD/io500 $io500_ini --timestamp $timestamp : -np 140 -env IM_CLIENT_NET_IF ib1-verbs taskset -c 14-27 "

#io500_mpiargs="-np 28 -ppn 28 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_NUM_HCAS 1 -genv MV2_USE_RDMA_CM 0 $BINDING -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_ENABLE_SGL 1 -genv LD_PRELOAD /flash/io500/posix_2_ime/libposix2ime.so"
}

# Set directories where benchmark files are created and where the results go.
# If you want to set up stripe tuning on your output directories or anything
# similar, then this is the right place to do it.
function setup_directories {
  local workdir
  local resultdir
  local ts

  mkdir -p $io500_workdir $io500_resultdir

  eval $(grep "^BFSDIR" /etc/ddn/ime/ime-fuse.conf)
  eval $(grep "^MNTDIR" /etc/ddn/ime/ime-fuse.conf)
  bfspath=$(echo "$BFSDIR${io500_workdir#"$MNTDIR"}")

#  lfs setstripe -L mdt -E 1M $bfspath
#  lfs setdirstripe -D -c -1 $bfspath


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

io500_ini="${1:-""}"
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
