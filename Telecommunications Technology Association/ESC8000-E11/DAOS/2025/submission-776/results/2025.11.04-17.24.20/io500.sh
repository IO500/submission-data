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
io500_ini="$1"          # You can set the ini file here
io500_mpirun="mpirun"

if [[ -z "${DAOS_POOL}" ]]; then
  DAOS_POOL="tank"
fi

if [[ -z "${DAOS_CONT}" ]]; then
  DAOS_CONT="posix_container"
fi

HOSTS_LIST=(
  #"Client-1",
  "Client-2",
  "Client-3",
  "Client-4",
  "Client-5",
  "Client-6",
  "Client-7",
  "Client-8"
)

#PROCS_PER_NODE="$(nproc)"

PROCS_PER_NODE=144
NPROC="$((PROCS_PER_NODE * ${#HOSTS_LIST[@]}))"

#FIND_NPROC="$((NPROC / 3))"
#FIND_QLEN="$((FIND_NPROC * 45))"

FIND_NPROC="448"
FIND_QLEN="20160"

#io500_mpiargs="-np 1344 -ppn 192"
#io500_mpiargs="-np 1008 -ppn 144"
io500_mpiargs="-np $NPROC -ppn $PROCS_PER_NODE"

#io500_mpiargs+=" -bind-to numa -map-by numa"
io500_mpiargs+=" -bind-to core -map-by core"

OLD_IFS=$IFS
IFS=,
HOSTS_STR="${HOSTS_LIST[*]}"
IFS=$OLD_IFS

io500_mpiargs+=" -hosts $HOSTS_STR"

io500_mpiargs+=" -genv DAOS_POOL $DAOS_POOL"
io500_mpiargs+=" -genv DAOS_CONT $DAOS_CONT"

io500_mpiargs+=" -genv CRT_CTX_SHARE_ADDR 1"
io500_mpiargs+=" -genv CRT_CTX_NUM 8"
io500_mpiargs+=" -genv CRT_CREDIT_EP_CTX 0"
io500_mpiargs+=" -genv CRT_MRC_ENABLE 1"
io500_mpiargs+=" -genv CRT_TIMEOUT 600"

#io500_mpiargs+=" -genv FI_CXI_RX_MATCH_MODE hybrid"
#io500_mpiargs+=" -genv FI_CXI_REQ_BUF_SIZE 8388608"
#io500_mpiargs+=" -genv FI_CXI_OFLOW_BUF_SIZE 8388608"
#io500_mpiargs+=" -genv FI_CXI_REQ_BUF_MIN_POSTED 8"
#io500_mpiargs+=" -genv FI_CXI_DEFAULT_CQ_SIZE 131072"
#io500_mpiargs+=" -genv FI_CXI_CQ_FILL_PERCENT 20"
#io500_mpiargs+=" -genv FI_OFI_RXM_BUFFER_SIZE 131072"
#io500_mpiargs+=" -genv FI_OFI_RXM_SAR_LIMIT 131072"
io500_mpiargs+=" -genv FI_OFI_RXM_USE_SRX 1"
io500_mpiargs+=" -genv FI_UNIVERSE_SIZE 16383"
io500_mpiargs+=" -genv FI_VERBS_INLINE_SIZE 128"
io500_mpiargs+=" -genv FI_VERBS_PREFER_XRC 1"

#io500_mpiargs+=" -genv HDF5_PARAPREFIX \"daos:\" "
#io500_mpiargs+=" -genv ROMIO_FSTYPE_FORCE \"daos:\""
#io500_mpiargs+=" -genv MPICH_MPIIO_HINTS \"romis_ds_write:disable;romio_cb_write:enable;cc_nodes:8\""
#io500_mpiargs+=" -genv MPICH_MPIIO_HINTS_DISPLAY 1"

#io500_mpiargs+=" -genv MPIR_CVAR_BCAST_POSIX_INTRA_ALGORITHM mpir"
#io500_mpiargs+=" -genv MPIR_CVAR_ALLREDUCE_POSIX_INTRA_ALGORITHM mpir"
#io500_mpiargs+=" -genv MPIR_CVAR_BARRIER_POSIX_INTRA_ALGORITHM mpir"
#io500_mpiargs+=" -genv MPIR_CVAR_REDUCE_POSIX_INTRA_ALGORITHM mpir"

#io500_mpiargs+=" -genv FI_PROVIDER verbs"

# for default?
#io500_mpiargs+=" -genv MPICH_MPIIO_HINTS \"romio_cb_write:disable;romio_cb_read:disable;romio_no_indep_rw=false\""

# for ior-easy
#io500_mpiargs+=" -genv MPICH_MPIIO_HINTS \"romio_ds_write:disable;romio_ds_read:disable;romio_cb_write:disable;romio_cb_read:disable:romio_no_indep_rw=true\""

# for ior-hard
#io500_mpiargs+=" -genv MPICH_MPIIO_HINTS \"romio_cb_write:enable;romio_cb_read:enable;cb_buffer_size:67108864;cb_nodes:16\""

# for mdtest
#io500_mpiarsg+=" -genv MPICH_MPIIO_HINTS \"romio_cb_write:disable;romio_cb_read:disable;romio_no_indep_rw=false\""

if [ -f "${io500_ini//.ini/-tmpl.ini}" ]; then
  [ -f "$io500_ini" ] && mv "$io500_ini" "${io500_ini}.bak"

  cp -af "${io500_ini//.ini/-tmpl.ini}" "$io500_ini"

  sed -i -e "s/@DAOS_POOL/$DAOS_POOL/g" "$io500_ini"
  sed -i -e "s/@DAOS_CONT/$DAOS_CONT/g" "$io500_ini"
  sed -i -e "s/@FIND_NPROC/$FIND_NPROC/g" "$io500_ini"
  sed -i -e "s/@FIND_QLEN/$FIND_QLEN/g" "$io500_ini"
fi

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
