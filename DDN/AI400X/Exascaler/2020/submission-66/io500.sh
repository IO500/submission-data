#!/bin/bash
#SBATCH --job-name=io500-ai400
#SBATCH -P 32n
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=16
#SBATCH -o io_500_out_%j
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

LUSTRE_MGS=10.0.11.224@o2ib10
#LUSTRE_MDS=es400nv-vm[1-4],es400xmd-vm[1-4]
#LUSTRE_OSS=es400nv-vm[1-4],es400xmd-vm[1-4]
LUSTRE_MDS=es400nv-vm[1-4]
LUSTRE_OSS=es400nv-vm[1-4]
#LUSTRE_CLIENT=${SLURM_JOB_NODELIST}
LUSTRE_CLIENT=ec[01-10]
FSNAME=/ai400
MNT=/ai400_0

ROOT=`pwd`
#module purge
#module load mpi/gcc/openmpi/4.0.4
export PATH=/usr/mpi/gcc/openmpi-4.0.3rc4/bin:$PATH
PDSH="pdsh"

# Lustre MDS/OSS Setting
$PDSH -w ${LUSTRE_MDS} "echo 128 > /sys/module/mdt/parameters/max_mod_rpcs_per_client"
$PDSH -w ${LUSTRE_OSS},${LUSTRE_MDS} "sysctl -w vm.min_free_kbytes=524288"
$PDSH -w ${LUSTRE_OSS} lctl set_param \
osd-ldiskfs.*.read_cache_enable=0 \
osd-ldiskfs.*.writethrough_cache_enable=0 \
obdfilter.*.brw_size=16 \
obdfilter.*.precreate_batch=1024

# ReMount Lustre Client
#$PDSH -w ${LUSTRE_CLIENT} umount -t lustre -a
#$PDSH -w ${LUSTRE_CLIENT} mount -t lustre ${LUSTRE_MGS}:${FSNAME} ${MNT}
$PDSH -w ${LUSTRE_CLIENT},${LUSTRE_MDS},${LUSTRE_OSS} lctl get_param version
sleep 2

# Lustre Client Setting
$PDSH -w ${LUSTRE_CLIENT} lctl set_param \
osc.*.max_pages_per_rpc=16M \
osc.*.max_rpcs_in_flight=16 \
osc.*.max_dirty_mb=512 \
osc.*.checksums=0 \
llite.*.max_read_ahead_mb=2048 \
llite.*.max_read_ahead_per_file_mb=256 \
llite.*.max_cached_mb=10000 \
ldlm.namespaces.*.lru_size=0 \
ldlm.namespaces.*.lru_max_age=5000 \
mdc.*.max_rpcs_in_flight=128 \
mdc.*.max_mod_rpcs_in_flight=127
sleep 2

# Cleanup & TRIM to all OSTs
$PDSH -w ${LUSTRE_CLIENT} lctl set_param ldlm.namespaces.*.lru_size=clear
#$PDSH -w ${LUSTRE_OSS} fstrim -av
$PDSH -w ${LUSTRE_MDS},${LUSTRE_OSS} "echo 3 > /proc/sys/vm/drop_caches"
$PDSH -w ${LUSTRE_CLIENT} "cpupower frequency-set -g performance"

#
# INSTRUCTIONS:
# This script takes its parameters from the same .ini file as io500 binary.

function setup_paths {
  # Set the paths to the binaries and how to launch MPI jobs.
  # If you ran ./utilities/prepare.sh successfully, then binaries are in ./bin/
  io500_ior_cmd=$PWD/bin/ior
  io500_mdtest_cmd=$PWD/bin/mdtest
  io500_mdreal_cmd=$PWD/bin/md-real-io
  #io500_mpirun="/work/tools/mpi/gcc/openmpi/4.0.4/bin/mpirun"
  io500_mpirun="mpirun"
  io500_mpiargs="--allow-run-as-root -np 160 -hostfile ./hostfile -npernode 16 singularity.sh --bind /work -B /usr/mpi -B /usr/lib64 -B /sys/class/infiniband_verbs -B /bin -B /sbin -B /etc/libibverbs.d centos8.sif "
}

function setup_directories {
  local workdir
  local resultdir
  local ts

  # set directories where benchmark files are created and where the results go
  # If you want to set up stripe tuning on your output directories or anything
  # similar, then this is the right place to do it.  This creates the output
  # directories for both the app run and the script run.

  timestamp=$(date +%Y.%m.%d-%H.%M.%S)           # create a uniquifier
  [ $(get_ini_global_param timestamp-datadir True) != "False" ] &&
	ts="$timestamp" || ts="io500"
  # directory where the data will be stored
  workdir=$(get_ini_global_param datadir $PWD/datafiles)/$ts
  io500_workdir=$workdir-scr
  [ $(get_ini_global_param timestamp-resultdir True) != "False" ] &&
	ts="$timestamp" || ts="io500"
  # the directory where the output results will be kept
  resultdir=$(get_ini_global_param resultdir $PWD/results)/$ts
  io500_result_dir=$resultdir-scr

  mkdir -p $workdir-{scr,app} $resultdir-{scr,app}

  lfs setdirstripe -c 8 -i 0,1,2,3,4,5,6,7 $workdir-app/mdtest-{easy,hard}
  lfs setdirstripe -c 8 -i 0,1,2,3,4,5,6,7 $workdir-scr/mdt_{easy,hard}
  #lfs setdirstripe -c 4 -i 0,1,2,3 $workdir-app/mdtest-{easy,hard}
  #lfs setdirstripe -c 4 -i 0,1,2,3 $workdir-scr/mdt_{easy,hard}
  lfs setdirstripe -c 8 -D $workdir-app/mdtest-{easy,hard}
  lfs setdirstripe -c 8 -D $workdir-scr/mdt_{easy,hard}
  lfs setstripe -L mdt -E 1M $workdir-app/mdtest-{easy,hard} 
  lfs setstripe -L mdt -E 1M $workdir-scr/mdt_{easy,hard}

  mkdir $workdir-app/ior-hard $workdir-scr/ior_hard
  lfs setstripe -C 240 -S 16M $workdir-app/ior-hard $workdir-scr/ior_hard
}

# you should not edit anything below this line
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

function get_ini_param() {
  local section="$1"
  local param="$2"
  local default="$3"

  # try and get the most-specific param first, then more generic params
  val=$(get_ini_section_param $section $param)
  [ -n "$val" ] || val="$(get_ini_section_param ${section%-*} $param)"
  [ -n "$val" ] || val="$(get_ini_section_param global $param)"

  echo "${val:-$default}" |
  	sed -e 's/[Ff][Aa][Ll][Ss][Ee]/False/' -e 's/[Tt][Rr][Uu][Ee]/True/'
}

function get_ini_run_param() {
  local section="$1"
  local default="$2"
  local val

  val=$(get_ini_section_param $section noRun)

  # logic is reversed from "noRun=TRUE" to "run=False"
  [[ $val = [Tt][Rr][Uu][Ee] ]] && echo "False" || echo "$default"
}

function get_ini_global_param() {
  local param="$1"
  local default="$2"
  local val

  val=$(get_ini_section_param global $param |
  	sed -e 's/[Ff][Aa][Ll][Ss][Ee]/False/' -e 's/[Tt][Rr][Uu][Ee]/True/')

  echo "${val:-$default}"
}

# does the write phase and enables the subsequent read
io500_run_ior_easy="$(get_ini_run_param ior-easy True)"
# does the creat phase and enables the subsequent stat
io500_run_md_easy="$(get_ini_run_param mdtest-easy True)"
# does the write phase and enables the subsequent read
io500_run_ior_hard="$(get_ini_run_param ior-hard True)"
# does the creat phase and enables the subsequent read
io500_run_md_hard="$(get_ini_run_param mdtest-hard True)"
io500_run_find="$(get_ini_run_param find True)"
io500_run_ior_easy_read="$(get_ini_run_param ior-easy-read True)"
io500_run_md_easy_stat="$(get_ini_run_param mdtest-easy-stat True)"
io500_run_ior_hard_read="$(get_ini_run_param ior-hard-read True)"
io500_run_md_hard_stat="$(get_ini_run_param mdtest-easy-stat True)"
io500_run_md_hard_read="$(get_ini_run_param mdtest-easy-stat True)"
# turn this off if you want to just run find by itself
io500_run_md_easy_delete="$(get_ini_run_param mdtest-easy-delete True)"
# turn this off if you want to just run find by itself
io500_run_md_hard_delete="$(get_ini_run_param mdtest-hard-delete True)"
io500_run_md_hard_delete="$(get_ini_run_param mdtest-hard-delete True)"
io500_run_mdreal="$(get_ini_run_param mdreal False)"
# attempt to clean the cache after every benchmark, useful for validating the performance results and for testing with a local node; it uses the io500_clean_cache_cmd (can be overwritten); make sure the user can write to /proc/sys/vm/drop_caches
io500_clean_cache="$(get_ini_global_param drop-caches False)"
io500_clean_cache_cmd="$(get_ini_global_param drop-caches-cmd)"
io500_cleanup_workdir="$(get_ini_run_param cleanup)"
# Stonewalling timer, set to 300 to be an official run; set to 0, if you never want to abort...
io500_stonewall_timer=$(get_ini_param debug stonewall-time 300)
# Choose regular for an official regular submission or scc for a Student Cluster Competition submission to execute the test cases for 30 seconds instead of 300 seconds
io500_rules="regular"

# to run this benchmark, find and edit each of these functions.  Please also
# also edit 'extra_description' function to help us collect the required data.
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

  if [[ ! -s "system-information.txt" ]]; then
    echo "Warning: please create a system-information.txt description by"
    echo "copying the information from https://vi4io.org/io500-info-creator/"
  else
    cp "system-information.txt" $io500_result_dir
  fi

  create_tarball
}

function setup_ior_easy {
  local params

  io500_ior_easy_size=$(get_ini_param ior-easy blockSize 9920000m | tr -d m)
  val=$(get_ini_param ior-easy API POSIX)
  [ -n "$val" ] && params+=" -a $val"
  val="$(get_ini_param ior-easy transferSize)"
  [ -n "$val" ] && params+=" -t $val"
  val="$(get_ini_param ior-easy hintsFileName)"
  [ -n "$val" ] && params+=" -U $val"
  val="$(get_ini_param ior-easy posix.odirect)"
  [ "$val" = "True" ] && params+=" --posix.odirect"
  val="$(get_ini_param ior-easy verbosity)"
  if [ -n "$val" ]; then
    for i in $(seq $val); do
      params+=" -v"
    done
  fi
  io500_ior_easy_params="$params"
  echo -n ""
}

function setup_mdt_easy {
  io500_mdtest_easy_params="-u -L" # unique dir per thread, files only at leaves

  val=$(get_ini_param mdtest-easy n 1000000)
  [ -n "$val" ] && io500_mdtest_easy_files_per_proc="$val"
  val=$(get_ini_param mdtest-easy API POSIX)
  [ -n "$val" ] && io500_mdtest_easy_params+=" -a $val"
  val=$(get_ini_param mdtest-easy posix.odirect)
  [ "$val" = "True" ] && io500_mdtest_easy_params+=" --posix.odirect"
  echo -n ""
}

function setup_ior_hard {
  local params

  io500_ior_hard_api=$(get_ini_param ior-hard API POSIX)
  io500_ior_hard_writes_per_proc="$(get_ini_param ior-hard segmentCount 10000000)"
  val="$(get_ini_param ior-hard hintsFileName)"
  [ -n "$val" ] && params+=" -U $val"
  val="$(get_ini_param ior-hard posix.odirect)"
  [ "$val" = "True" ] && params+=" --posix.odirect"
  val="$(get_ini_param ior-easy verbosity)"
  if [ -n "$val" ]; then
    for i in $(seq $val); do
      params+=" -v"
    done
  fi
  io500_ior_hard_api_specific_options="$params"
  echo -n ""
}

function setup_mdt_hard {
  val=$(get_ini_param mdtest-hard n 1000000)
  [ -n "$val" ] && io500_mdtest_hard_files_per_proc="$val"
  io500_mdtest_hard_api="$(get_ini_param mdtest-hard API POSIX)"
  io500_mdtest_hard_api_specific_options=""
  echo -n ""
}

function setup_find {
  val="$(get_ini_param find external-script)"
  [ -z "$val" ] && io500_find_mpi="True" && io500_find_cmd="$PWD/bin/pfind" ||
    io500_find_cmd="$val"
  # uses stonewalling, run pfind
  io500_find_cmd_args="$(get_ini_param find external-extra-args)"
  echo -n ""
}

function setup_mdreal {
  echo -n ""
}

function run_benchmarks {
  local app_first=$((RANDOM % 100))
  local app_rc=0

  # run the app and C version in random order to try and avoid bias
  (( app_first >= 50 )) && $io500_mpirun $io500_mpiargs $PWD/io500 $io500_ini --timestamp $timestamp || app_rc=$?

  # Important: source the io500_fixed.sh script.  Do not change it. If you
  # discover a need to change it, please email the mailing list to discuss.
  source build/io500-dev/utilities/io500_fixed.sh 2>&1 |
    tee $io500_result_dir/io-500-summary.$timestamp.txt

  (( $app_first >= 50 )) && return $app_rc

  echo "The io500.sh was run"
  echo
  echo "Running the C version of the benchmark now"
  # run the app and C version in random order to try and avoid bias
  $io500_mpirun $io500_mpiargs $PWD/io500 $io500_ini --timestamp $timestamp
}

create_tarball() {
  local sourcedir=$(dirname $io500_result_dir)
  local fname=$(basename ${io500_result_dir%-scr})
  local tarball=$sourcedir/io500-$HOSTNAME-$fname.tgz

  cp -v $0 $io500_ini $io500_result_dir
  tar czf $tarball -C $sourcedir $fname-{app,scr}
  echo "Created result tarball $tarball"
}

# Information fields; these provide information about your system hardware
# Use https://vi4io.org/io500-info-creator/ to generate information about
# your hardware that you want to include publicly!
function extra_description {
  # UPDATE: Please add your information into "system-information.txt" pasting the output of the info-creator
  # EXAMPLE:
  # io500_info_system_name='xxx'
  # DO NOT ADD IT HERE
  :
}

main
