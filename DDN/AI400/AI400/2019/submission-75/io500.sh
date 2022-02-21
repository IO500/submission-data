#!/bin/bash
#SBATCH --job-name=io500-ai400-2
#SBATCH -P 32n
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=24
#SBATCH -o io_500_out_%j
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

LUSTRE_MDS=es400nv-vm[1-4]
LUSTRE_OSS=es400nv-vm[1-4]
#LUSTRE_CLIENT=${SLURM_JOB_NODELIST}
LUSTRE_CLIENT=c[01-10]
LUSTRE_CLIENT_CONTAINER=${LUSTRE_CLIENT}-c[0-3]
MGS=10.0.11.224@o2ib10
FSNAME=/ai400
MNT=/ai400

ROOT=`pwd`
module purge
module load mpi/gcc/openmpi/2.1.6
PDSH="pdsh"

#./utilities/prepare.sh

for i in `seq 0 3`; do 
	$PDSH -w ${LUSTRE_CLIENT} "docker stop %h-c$i"
	$PDSH -w ${LUSTRE_CLIENT} "docker rm %h-c$i"
done

$PDSH -w ${LUSTRE_CLIENT} "docker build -t lustreclient ${PWD}/."
for i in `seq 0 3`; do
	$PDSH -w ${LUSTRE_CLIENT} "docker run -h %h-c$i --name %h-c$i -d -p 2000$i:2000$i -e SSH_PORT=2000$i -v /work:/work -v /dev/infiniband:/dev/infiniband -v /usr/lib64:/usr/lib64 -v /sys/class/infiniband_verbs:/sys/class/infiniband_verbs -v /etc/libibverbs.d:/etc/libibverbs.d --privileged lustreclient"
done
$PDSH -w ${LUSTRE_CLIENT} 'docker ps'

# Lustre MDS/OSS Setting
$PDSH -w ${LUSTRE_MDS} "echo 128 > /sys/module/mdt/parameters/max_mod_rpcs_per_client"
$PDSH -w ${LUSTRE_OSS},${LUSTRE_MDS} "sysctl -w vm.min_free_kbytes=524288"
$PDSH -w ${LUSTRE_OSS} lctl set_param \
osd-ldiskfs.*.read_cache_enable=0 \
osd-ldiskfs.*.writethrough_cache_enable=0 \
obdfilter.*.brw_size=16 \
obdfilter.*.precreate_batch=1024

# ReMount Lustre Client
$PDSH -w ${LUSTRE_CLIENT_CONTAINER} umount -t lustre -a
$PDSH -w ${LUSTRE_CLIENT_CONTAINER} mount -t lustre ${MGS}:${FSNAME} ${MNT}
sleep 2

# Lustre Client Setting
$PDSH -w ${LUSTRE_CLIENT_CONTAINER} lctl set_param \
osc.*.max_pages_per_rpc=16M \
osc.*.max_rpcs_in_flight=16 \
osc.*.max_dirty_mb=512 \
osc.*.checksums=0 \
llite.*.max_read_ahead_mb=2048 \
llite.*.max_read_ahead_per_file_mb=256 \
llite.*.max_cached_mb=16384 \
ldlm.namespaces.*.lru_size=0 \
ldlm.namespaces.*.lru_max_age=5000 \
mdc.*.max_rpcs_in_flight=128 \
mdc.*.max_mod_rpcs_in_flight=127
sleep 2

# Cleanup & TRIM to all OSTs
$PDSH -w ${LUSTRE_CLIENT_CONTAINER} lctl set_param ldlm.namespaces.*.lru_size=clear
#$PDSH -w ${LUSTRE_OSS} fstrim -av
$PDSH -w ${LUSTRE_MDS},${LUSTRE_OSS} "echo 3 > /proc/sys/vm/drop_caches"
$PDSH -w ${LUSTRE_CLIENT} "cpupower frequency-set -g performance"

#
# INSTRUCTIONS:
# Edit this file as needed for your machine.
# This simplified version is just for running on a single node.
# It is a simplified version of the site-configs/sandia/startup.sh which include SLURM directives.
# Most of the variables set in here are needed for io500_fixed.sh which gets sourced at the end of this.
# Please also edit 'extra_description' function.

set -euo pipefail  # better error handling

# turn these to True successively while you debug and tune this benchmark.
# for each one that you turn to true, go and edit the appropriate function.
# to find the function name, see the 'main' function.
# These are listed in the order that they run.
io500_run_ior_easy="True" # does the write phase and enables the subsequent read
io500_run_md_easy="True"  # does the creat phase and enables the subsequent stat
io500_run_ior_hard="True" # does the write phase and enables the subsequent read
io500_run_md_hard="True"  # does the creat phase and enables the subsequent read
io500_run_find="True"
io500_run_ior_easy_read="True"
io500_run_md_easy_stat="True"
io500_run_ior_hard_read="True"
io500_run_md_hard_stat="True"
io500_run_md_hard_read="True"
io500_run_md_easy_delete="True" # turn this off if you want to just run find by itself
io500_run_md_hard_delete="True" # turn this off if you want to just run find by itself
io500_run_mdreal="False"  # this one is optional
io500_cleanup_workdir="False"  # this flag is currently ignored. You'll need to clean up your data files manually if you want to.
io500_clean_cache="False" # attempt to clean the cache after every benchmark, useful for validating the performance results and for testing with a local node; it uses the io500_clean_cache_cmd (can be overwritten); make sure the user can write to /proc/sys/vm/drop_caches
io500_stonewall_timer=300 # Stonewalling timer, set to 300 to be an official run; set to 0, if you never want to abort...
io500_rules="regular" # Choose regular for an official regular submission or scc for a Student Cluster Competition submission to execute the test cases for 30 seconds instead of 300 seconds

io500_mdtest_easy_files_per_proc=200000
io500_mdtest_hard_files_per_proc=142500
io500_ior_hard_writes_per_proc=125000
io500_ior_easy_size=44000

# to run this benchmark, find and edit each of these functions.
# please also edit 'extra_description' function to help us collect the required data.
function main {
  setup_directories
  setup_paths
  setup_ior_easy # required if you want a complete score
  setup_ior_hard # required if you want a complete score
  setup_mdt_easy # required if you want a complete score
  setup_mdt_hard # required if you want a complete score
  setup_find     # required if you want a complete score
  setup_mdreal   # optional
  run_benchmarks
}

function setup_directories {
  # set directories for where the benchmark files are created and where the results will go.
  # If you want to set up stripe tuning on your output directories or anything similar, then this is good place to do it.
  timestamp=`date +%Y.%m.%d-%H.%M.%S`           # create a uniquifier
  io500_workdir=${MNT}/datafiles/io500.$timestamp # directory where the data will be stored
  io500_result_dir=$PWD/results/$timestamp      # the directory where the output results will be kept
  mkdir -p $io500_workdir $io500_result_dir
  mkdir -p $io500_workdir/ior_hard $io500_workdir/ior_easy
  lfs setdirstripe -c 4 $io500_workdir/mdt_easy
  lfs setdirstripe -c 4 $io500_workdir/mdt_hard
  lfs setdirstripe -c 4 -D $io500_workdir/mdt_easy
  lfs setdirstripe -c 4 -D $io500_workdir/mdt_hard

  lfs setstripe -L mdt -E 1M $io500_workdir/mdt_easy
  lfs setstripe -L mdt -E 1M $io500_workdir/mdt_hard
  lfs setstripe -C 240 -S 16M $io500_workdir/ior_hard
}

function setup_paths {
  # Set the paths to the binaries.  If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  io500_mpirun="/work/tools/mpi/gcc/openmpi/2.1.1/bin/mpirun"
  io500_mpiargs="--allow-run-as-root -np 240 -npernode 6 -hostfile ./hostfile-container"
}

function setup_ior_easy {
  io500_ior_easy_params="-t 2048k "
  #io500_ior_easy_params="-t 16m "
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves
}

function setup_ior_hard {
  io500_ior_hard_api="POSIX"
  io500_ior_hard_api_specific_options=""
}

function setup_mdt_hard {
  io500_mdtest_hard_api="POSIX"
  io500_mdtest_hard_api_specific_options=""
}

function setup_find {
  #
  # setup the find command. This is an area where innovation is allowed.
  #    There are three default options provided. One is a serial find, one is python
  #    parallel version, one is C parallel version.  Current default is to use serial.
  #    But it is very slow. We recommend to either customize or use the C parallel version.
  #    For GPFS, we recommend to use the provided mmfind wrapper described below.
  #    Instructions below.
  #    If a custom approach is used, please provide enough info so others can reproduce.

  # the serial version that should run (SLOWLY) without modification
  #io500_find_mpi="False"
  #io500_find_cmd=$PWD/bin/sfind.sh
  #io500_find_cmd_args=""

  # a parallel version in C, the -s adds a stonewall
  #   for a real run, turn -s (stonewall) off or set it at 300 or more
  #   to prepare this (assuming you've run ./utilities/prepare.sh already):
  #   > cd build/pfind
  #   > ./prepare.sh
  #   > ./compile.sh
  #   > cp pfind ../../bin/
  #   If you use io500_find_mpi="True", then this will run with the same
  #   number of MPI nodes and ranks as the other phases.
  #   If you prefer another number, and fewer might be better here,
  #   Then you can set io500_find_mpi to be "False" and write a wrapper
  #   script for this which sets up MPI as you would like.  Then change
  #   io500_find_cmd to point to your wrapper script.
  io500_find_mpi="True"
  io500_find_cmd="$PWD/bin/pfind"
  # uses stonewalling, run pfind
  io500_find_cmd_args=""

  # for GPFS systems, you should probably use the provided mmfind wrapper
  # if you used ./utilities/prepare.sh, you'll find this wrapper in ./bin/mmfind.sh
  #io500_find_mpi="False"
  #io500_find_cmd="$PWD/bin/mmfind.sh"
  #io500_find_cmd_args=""
}

function setup_mdreal {
  echo -n ""
}

function run_benchmarks {
  # Important: source the io500_fixed.sh script.  Do not change it. If you discover
  # a need to change it, please email the mailing list to discuss
  source ./utilities/io500_fixed.sh 2>&1 | tee $io500_result_dir/io-500-summary.$timestamp.txt
}

# Information fields; these provide information about your system hardware
# Use https://vi4io.org/io500-info-creator/ to generate information about your hardware
# that you want to include publicly!
function extra_description {
  # TODO: Please add your information using the info-creator!
  # EXAMPLE:
  io500_info_system_name='xxx'      # e.g. Oakforest-PACS
}

main
