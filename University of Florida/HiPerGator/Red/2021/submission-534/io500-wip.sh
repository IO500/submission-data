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
io500_mpirun="mpiexec"
#ntasks=960
#ntasks=320
#ntasks=512
#ntasks=640
ntasks=4480
#ntasks=2240
export LD_LIBRARY_PATH="/usr/lib64:/home/mhill2/burn-in/apps/cuda/11.0.2/lib64:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/nccl_rdma_sharp_plugin/lib:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/hmc/lib:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/ucx/lib/ucx:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/ucx/lib:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/sharp/lib:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/hcoll/lib:/home/mhill2/burn-in/apps/hpcx-v2.7.4-gcc-MLNX_OFED_LINUX-5.1-0.6.6.0-redhat7.7-x86_64/ompi/lib:/opt/slurm/lib64:"
#io500_mpiargs="-np 2"
#io500_mpiargs='-np 2560 --hostfile /lustre_ai400x/io500/hostfile.10x256  -x UCX_NET_DEVICES=mlx5_0:1 --bind-to none --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4'
#io500_mpiargs="-np $ntasks --hostfile /lustre_ai400x/io500/hostfile.10x128.cpu_npartitions_32  -x UCX_NET_DEVICES=mlx5_0:1 --bind-to none --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 /lustre_ai400x/io500/bind-wip.sh "
# cpu_npartitions=8 (default)
#io500_mpiargs="--report-bindings --map-by ppr:8:numa:pe=1 --bind-to core -np $ntasks -host c0800a-s35:-1,c0804a-s35:-1,c0900a-s35:-1,c0904a-s35:-1,c0906a-s35:-1,c0910a-s35:-1,c1000a-s35:-1,c1006a-s35:-1,c1100a-s35:-1,c1106a-s35:-1 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "
# cpu_npartitions=32
#io500_mpiargs="--report-bindings --map-by ppr:12:numa:pe=1 --bind-to core -np $ntasks -host c0800a-s11:-1,c0804a-s11:-1,c0900a-s11:-1,c0904a-s11:-1,c0906a-s11:-1,c0910a-s11:-1,c1000a-s11:-1,c1006a-s11:-1,c1100a-s11:-1,c1106a-s11:-1 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "
#io500_mpiargs="--bind-to core -np $ntasks --hostfile /lustre_ai400x/io500/hostfile.10x32.cpu_npartitions_32 --rankfile /lustre_ai400x/io500/rankfile.10x32.cpu_npartitions_32 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "
#io500_mpiargs="--bind-to core -np $ntasks --hostfile /lustre_ai400x/io500/hostfile.10x64.cpu_npartitions_32 --rankfile /lustre_ai400x/io500/rankfile.10x64.cpu_npartitions_32 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "

io500_mpiargs="--bind-to core -np $ntasks --hostfile /lustre_ai400x/io500/hostfile.140x32 --rankfile /lustre_ai400x/io500/rankfile.140x32 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "
#io500_mpiargs="--bind-to core -np $ntasks --hostfile /lustre_ai400x/io500/hostfile.140x16 --rankfile /lustre_ai400x/io500/rankfile.140x16 -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH -x UCX_TLS=cma,rc,mm --mca pml ucx --mca btl ^openib,smcuda --mca oob_tcp_if_include bridge-1145 --mca btl_tcp_if_exclude virbr0,docker0,ib4,ib9 --mca btl_openib_if_exclude mlx5_10,mlx5_4 "

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
  mkdir -p $workdir/ior-easy $workdir/ior-hard $workdir/ior-rnd
  local osts=$(lfs df $workdir | grep -c OST)
  lfs setstripe -c 1 -i -1 -S 16M $workdir/ior-easy
  # Try overstriping for ior-hard to improve scaling, or use wide striping
  #lfs setstripe -C $((osts * 4)) $workdir/ior-hard
  #lfs setstripe -C 80 -S 16M $workdir/ior-hard
  #lfs setstripe -c 80 -S 1M $workdir/ior-hard
  #lfs setstripe -C 320 -S 16M $workdir/ior-hard
  lfs setstripe -C 400 -S 16M $workdir/ior-hard
  #lfs setstripe -C 480 -S 16M $workdir/ior-hard
  #lfs setstripe -C 640 -S 16M $workdir/ior-hard
  #  lfs setstripe -c -1 $workdir/ior-hard
  # Try to use DoM if available, otherwise use default for small files
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-easy || true #DoM?
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-hard || true #DoM?
  #lfs setstripe -E 64k -L mdt $workdir/mdtest-rnd
  #lfs setdirstripe -c 10 -i 0,1,2,3,4,5,6,7,8,9 $workdir/mdtest-easy
  #lfs setdirstripe -c 10 -D $workdir/mdtest-easy

  lfs setdirstripe -c 10 -i 0,1,2,3,4,5,6,7,8,9 $workdir/mdtest-easy
  lfs setdirstripe -c 10 -D $workdir/mdtest-easy
  lfs setstripe -L mdt -E 1M $workdir/mdtest-easy

  #lfs setdirstripe -c 1 -i -1 $workdir/mdtest-easy/test-dir.0-0
  #lfs setdirstripe -c 1 -i -1 -D $workdir/mdtest-easy/test-dir.0-0

  #lfs setdirstripe -c 1 -i -1 $workdir/mdtest-easy

  # HACK - NOT LEGAL
  #lfs mkdir -c 1 -i -1 $workdir/mdtest-easy/test-dir.0-0
  #lfs setdirstripe -c 1 -i -1 -D $workdir/mdtest-easy/test-dir.0-0
  # distribute every task in the job round-robin over our available MDTs
  #i=0
  #while [ $i -lt $ntasks ]; do
  #    mdt=`shuf -i 0-9 -n 1`
  #    #lfs mkdir -c 1 -i $mdt $workdir/mdtest-easy/test-dir.0-0/mdtest_tree.${i}.0
  #    i=`expr $i + 1`
  #done

  lfs setdirstripe -c 10 -i 0,1,2,3,4,5,6,7,8,9 $workdir/mdtest-hard
  lfs setdirstripe -c 10 -D $workdir/mdtest-hard
  #lfs setstripe -L mdt -E 1M $workdir/mdtest-hard

  lfs setdirstripe -c 10 -i 0,1,2,3,4,5,6,7,8,9 $workdir/mdtest-rnd
  lfs setdirstripe -c 10 -D $workdir/mdtest-rnd

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
  #$io500_mpirun $io500_mpiargs $PWD/bind-wip.sh $PWD/io500 $io500_ini --timestamp $timestamp
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
