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
  CNODES="jwc09n048,jwc09n072,jwc09n096,jwc09n099,jwc09n120,jwc09n144,jwc09n147,jwc09n174,jwc09n177,jwc09n021"
  BINDING="-genv MV2_CPU_MAPPING 0:1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20:21:22:23:24:25:26:27:28:29:30:31:32:33:34:35:36:37:38:39"

  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mpirun="/opt/ddn/mvapich/bin/mpirun"
  #io500_mpiargs=" -np 400 -ppn 40 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_HANDSHAKE_ENABLED 1 -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_ENABLE_SGL 1 -genv LD_PRELOAD /p/project/ddn-ime/SC20/posix_2_ime/libposix2ime.so -genv IM_CLIENT_BFS_PATH /p/scratch -genv IM_CLIENT_NO_MKNOD_CREATE 1 -genv IM_CLIENT_NO_LARGE_DIR_BUFFER 1"
  io500_mpiargs=" -np 400 -ppn 40 -genv LD_LIBRARY_PATH /opt/ddn/ime/lib:/opt/ddn/mvapich/lib64:\$LD_LIBRARY_PATH -genv IM_CLIENT_PGEOM 1+0 -genv MV2_HOMOGENEOUS_CLUSTER 1 -genv MV2_USE_RDMA_CM 0 $BINDING --hosts $CNODES -genv IM_CLIENT_MIN_CONNECTIONS 0 -genv IM_CLIENT_HANDSHAKE_ENABLED 1 -genv IM_CLIENT_NET_IF ib0-verbs,ib1-verbs -genv IM_CLIENT_ENABLE_SGL 1 "
}

# Set directories where benchmark files are created and where the results go.
# If you want to set up stripe tuning on your output directories or anything
# similar, then this is the right place to do it.
function setup_directories {
  local workdir
  local resultdir
  local bfspath

  mkdir -p $io500_workdir $io500_resultdir

  eval $(grep "^BFSDIR" /etc/ddn/ime/ime-fuse.conf)
  eval $(grep "^MNTDIR" /etc/ddn/ime/ime-fuse.conf)
  bfspath=$(echo "$BFSDIR${io500_workdir#"$MNTDIR"}")
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
