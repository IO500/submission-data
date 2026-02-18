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
io500_mpirun="${FS_MPI_PATH}mpiexec"
# io500_mpiargs="-x LD_PRELOAD=${FS_BINARY}build/lib/libfs_syscall.so:${FS_BINARY}build/lib/libmalloc_intercept.so -H  -np 5940 --allow-run-as-root --use-hwthread-cpus --mca btl_tcp_if_include enp69s0 --mca plm_rsh_no_tree_spawn 1"
# io500_mpiargs="--mca pml ob1 --mca btl tcp,self -x LD_PRELOAD=${FS_BINARY}build/lib/libfs_syscall.so:${FS_BINARY}build/lib/libmalloc_intercept.so -H  --allow-run-as-root --use-hwthread-cpus --mca btl_tcp_if_include enp69s0 --mca plm_rsh_no_tree_spawn 1"
io500_mpiargs="--mca pml ob1 --mca btl tcp,self -x LD_PRELOAD=${FS_BINARY}build/lib/libfs_syscall.so:${FS_BINARY}build/lib/libmalloc_intercept.so -H 10.1.101.156:120,10.1.101.2:120,10.1.101.182:120,10.1.100.152:120,10.1.101.109:120,10.1.100.28:120,10.1.100.20:120,10.1.100.242:120,10.1.101.49:120,10.1.100.19:120,10.1.101.15:120,10.1.101.1:120,10.1.101.235:120,10.1.101.151:120,10.1.101.21:120,10.1.101.7:120,10.1.100.50:120,10.1.101.78:120,10.1.101.223:120,10.1.101.200:120,10.1.101.210:120,10.1.101.213:120,10.1.101.226:120,10.1.101.227:120,10.1.101.220:120,10.1.101.146:120,10.1.101.178:120,10.1.101.112:120,10.1.101.174:120,10.1.101.103:120,10.1.100.196:120,10.1.101.35:120,10.1.100.228:120,10.1.101.6:120,10.1.101.81:120,10.1.100.109:120,10.1.100.205:120,10.1.101.234:120,10.1.101.228:120,10.1.101.203:120,10.1.101.214:120,10.1.101.233:120,10.1.101.216:120,10.1.101.202:120,10.1.101.204:120,10.1.101.205:120,10.1.101.224:120,10.1.101.199:120,10.1.101.120:120,10.1.100.195:120,10.1.100.184:120,10.1.101.66:120,10.1.100.191:120,10.1.101.90:120,10.1.101.8:120,10.1.100.186:120,10.1.100.193:120,10.1.101.121:120,10.1.100.216:120,10.1.101.39:120,10.1.101.192:120,10.1.100.173:120,10.1.101.27:120,10.1.101.96:120,10.1.100.215:120,10.1.101.193:120,10.1.100.188:120,10.1.101.18:120,10.1.101.95:120,10.1.100.240:120,10.1.101.84:120,10.1.101.46:120,10.1.101.190:120,10.1.101.82:120,10.1.100.231:120,10.1.100.226:120,10.1.101.9:120,10.1.101.51:120,10.1.100.102:120,10.1.100.230:120,10.1.101.132:120,10.1.101.175:120,10.1.101.104:120,10.1.101.144:120,10.1.101.117:120,10.1.101.98:120,10.1.100.172:120,10.1.101.72:120,10.1.100.246:120,10.1.101.170:120,10.1.100.222:120,10.1.101.71:120,10.1.100.237:120,10.1.101.138:120,10.1.101.184:120,10.1.101.180:120,10.1.100.211:120,10.1.100.190:120,10.1.101.30:120,10.1.100.203:120,10.1.101.23:120,10.1.100.177:120,10.1.101.16:120,10.1.100.175:120,10.1.101.166:120,10.1.101.70:120,10.1.100.247:120,10.1.101.91:120,10.1.101.105:120,10.1.100.140:120,10.1.101.3:120,10.1.101.50:120,10.1.101.100:120,10.1.101.29:120,10.1.101.31:120,10.1.101.67:120,10.1.100.232:120,10.1.102.16:120,10.1.102.14:120,10.1.102.4:120,10.1.101.249:120,10.1.102.3:120,10.1.100.185:120,10.1.101.26:120,10.1.100.183:120,10.1.101.34:120,10.1.101.42:120,10.1.101.44:120,10.1.101.164:120,10.1.101.139:120,10.1.100.37:120,10.1.100.14:120,10.1.100.38:120,10.1.100.32:120,10.1.100.16:120,10.1.100.36:120,10.1.100.15:120,10.1.100.33:120,10.1.101.19:120,10.1.100.225:120,10.1.100.236:120,10.1.100.207:120,10.1.100.234:120,10.1.100.176:120,10.1.100.194:120,10.1.101.60:120,10.1.100.254:120,10.1.101.143:120,10.1.101.20:120,10.1.102.13:120,10.1.102.21:120,10.1.101.250:120,10.1.102.155:120,10.1.102.7:120,10.1.102.15:120,10.1.102.6:120,10.1.100.180:120,10.1.101.37:120,10.1.101.10:120,10.1.100.253:120,10.1.101.179:120,10.1.101.126:120,10.1.101.122:120,10.1.101.40:120,10.1.101.171:120,10.1.101.52:120,10.1.101.13:120,10.1.100.189:120,10.1.100.244:120,10.1.100.178:120,10.1.100.174:120,10.1.101.73:120,10.1.100.157:120,10.1.100.136:120,10.1.100.76:120,10.1.100.229:120,10.1.100.96:120,10.1.101.62:120,10.1.100.143:120,10.1.100.227:120,10.1.101.129:120,10.1.100.144:120,10.1.100.166:120,10.1.100.141:120,10.1.101.55:120,10.1.100.148:120,10.1.100.89:120,10.1.100.52:120,10.1.100.125:120,10.1.100.62:120,10.1.100.51:120,10.1.100.55:120,10.1.100.47:120,10.1.100.162:120,10.1.100.40:120,10.1.100.233:120,10.1.100.35:120,10.1.101.25:120,10.1.101.187:120,10.1.101.141:120,10.1.101.65:120,10.1.101.118:120,10.1.100.179:120,10.1.101.106:120,10.1.100.251:120,10.1.100.206:120,10.1.101.12:120,10.1.101.54:120,10.1.101.24:120,10.1.100.243:120,10.1.101.57:120,10.1.100.213:120,10.1.100.218:120,10.1.100.248:120,10.1.101.83:120,10.1.100.44:120,10.1.100.42:120,10.1.100.39:120,10.1.100.41:120,10.1.100.46:120,10.1.100.43:120,10.1.100.48:120,10.1.100.67:120,10.1.100.86:120,10.1.100.59:120,10.1.100.54:120,10.1.101.76:120,10.1.100.73:120,10.1.100.70:120,10.1.100.88:120,10.1.100.66:120,10.1.100.64:120,10.1.100.71:120,10.1.100.65:120,10.1.100.6:120,10.1.100.10:120,10.1.101.74:120,10.1.101.177:120,10.1.100.209:120,10.1.100.154:120,10.1.101.137:120,10.1.100.132:120,10.1.100.107:120,10.1.100.200:120,10.1.101.124:120,10.1.100.149:120,10.1.100.169:120,10.1.101.45:120,10.1.101.38:120,10.1.101.125:120,10.1.101.47:120,10.1.100.123:120,10.1.100.111:120,10.1.101.36:120,10.1.101.102:120,10.1.101.75:120,10.1.100.199:120,10.1.101.136:120,10.1.101.243:120,10.1.100.153:120,10.1.100.8:120,10.1.100.9:120,10.1.101.248:120,10.1.101.236:120,10.1.100.238:120,10.1.101.238:120,10.1.101.246:120,10.1.100.217:120,10.1.101.79:120,10.1.100.92:120,10.1.100.160:120,10.1.100.163:120,10.1.101.155:120,10.1.100.113:120,10.1.101.191:120,10.1.101.64:120,10.1.101.163:120,10.1.100.100:120,10.1.100.78:120,10.1.100.139:120,10.1.100.159:120,10.1.100.112:120,10.1.100.91:120,10.1.100.147:120,10.1.100.84:120,10.1.100.133:120,10.1.100.74:120,10.1.101.152:120,10.1.100.104:120,10.1.100.75:120,10.1.100.146:120,10.1.100.151:120,10.1.101.231:120,10.1.100.82:120,10.1.100.214:120,10.1.100.250:120,10.1.101.32:120,10.1.101.59:120,10.1.100.212:120,10.1.100.99:120 -np 36000 --allow-run-as-root --use-hwthread-cpus --mca btl_tcp_if_include enp69s0 --mca plm_rsh_no_tree_spawn 1"

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
