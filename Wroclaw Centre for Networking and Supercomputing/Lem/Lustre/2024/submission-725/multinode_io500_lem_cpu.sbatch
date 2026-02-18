#!/bin/bash
#SBATCH -A kdm-staff
#SBATCH -q kdm-staff-2
#SBATCH -p lem-cpu
#SBATCH -t 24:00:00
#SBATCH --nodelist=r13ch03b[03-04],r13ch04b[01-04],r13ch05b[01-04]
#SBATCH --ntasks-per-node 128
#SBATCH --mem 0
#SBATCH --gres=storage:local:10G


source /etc/bashrc
module load OpenMPI/5.0.3-GCC-13.3.0

workdir="${SLURM_SUBMIT_DIR}"

MPIFLAGS="--mca orte_tmpdir_base /dev/shm --map-by node"
EXE="/lustre/pd03/teosps/io500/io500"
EXEFLAGS="--mode=standard"

function io500 {
  lustre="$1"
  NODES="$2"
  NSTRIPES="$3"

  NPERNODE=$4
  NPROC=$[ NPERNODE * NODES ]
  STRIPESIZE="${5}"
  DOMSTRIPESIZE="${6}"
  

  BASE_DIR="/lustre/${lustre}/teosps/io500_data"
  echo $BASE_DIR
  RESULTS_DIR="${workdir}/results_lem-cpu_multirail/${lustre}/nodes${NODES}/domstripe${DOMSTRIPESIZE}/stripes${NSTRIPES}"

  CONFIG_TEMPLATE="${workdir}/config-io500-submit.ini"
  CONFIG="${workdir}/config-running.ini"
  sed -e "s|@DATADIR|${BASE_DIR}|g" -e "s|@RESULTSDIR|${RESULTS_DIR}|g" ${CONFIG_TEMPLATE} > ${CONFIG}
  
  # Date Stamp for benchmark
  DS=`date +"%F_%H:%M:%S"`

  echo "################################################"
  echo "DOING: NODES= ${NODES} NPROC= ${NPROC} DOMSTRIPESIZE= ${DOMSTRIPESIZE} NSTRIPES= ${NSTRIPES} STRIPESIZE= ${STRIPESIZE}"
  echo "BASE_DIR: ${BASE_DIR}"
  echo "RESULTS_DIR: ${RESULTS_DIR}"
  echo "DATE: $DS"
  echo "################################################"
 
  
  mkdir -p ${BASE_DIR}/ior-easy ${BASE_DIR}/ior-hard ${BASE_DIR}/mdtest-easy ${BASE_DIR}/mdtest-hard
  lfs setstripe -L mdt -E 1M -E -1 -S ${STRIPESIZE} -c ${NSTRIPES} ${BASE_DIR}/ior-easy
  lfs setstripe -L mdt -E 1M -E -1 -S ${STRIPESIZE} -c -1 ${BASE_DIR}/ior-hard
  lfs setstripe -L mdt -E 1M -E -1 -S ${STRIPESIZE} -c -1 ${BASE_DIR}/mdtest-easy
  lfs setstripe -L mdt -E 1M -E -1 -S ${STRIPESIZE} -c -1 ${BASE_DIR}/mdtest-hard

  mpirun ${MPIFLAGS} -np ${NPROC} \
      ${EXE} ${CONFIG} ${EXEFLAGS} 
}
io500 pd03 10 8 32 "4M" "1M"
