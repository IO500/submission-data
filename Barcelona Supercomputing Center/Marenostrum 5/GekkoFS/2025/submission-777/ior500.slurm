#!/bin/bash
#SBATCH --job-name=ior500_test
#SBATCH --output=ior500.log
#SBATCH --nodes=200           # Adjust based on your needs
## SBATCH --ntasks-per-node=64   # Total tasks = nodes * ntasks-per-node
#SBATCH --time=3:00:00
#SBATCH --qos=gp_resa    # Specify your partition
# SBATCH --qos=gp_debug
# Load required modules
#SBATCH --exclusive

#module unload impi; module load ucx/1.16.0-gcc gcc/12.3.0 cmake ucx/1.16.0-gcc openmpi/4.1.5-gcc12.3
#module unload impi; module load ucx/1.16.0-gcc gcc/12.3.0 cmake ucx/1.16.0-gcc oneapi/2024.2
#module unload impi; module load ucx/1.16.0-gcc cmake ucx/1.16.0-gcc oneapi/2024.2 gcc/14.1.0_binutils241
module unload impi oneapi; module load ucx/1.16.0-gcc cmake ucx/1.16.0-gcc libfabric/1.21.0-gcc gcc/14.1.0_binutils241 openmpi/5.0.5-gcc gcc/14.1.0_binutils241
#intel/2023.2.0   2) impi/2021.10.0   3) mkl/2023.2.0   4) oneapi/2023.2.0   5) bsc/1.0   6) ucx/1.16.0-gcc   7) gcc/13.2.0   8) cmake/3.25.1
# Set locale settings
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
export OMPI_MCA_btl_openib_allow_ib=1 
export OMPI_MCA_opal_common_ucx_opal_mem_hooks=1
# Define base path for ADMIRE to avoid repetition
export ADMIRE_PATH=/gpfs/home/bsc/bsc025015/ADMIRE/iodeps

# Update library path
export LD_LIBRARY_PATH=${ADMIRE_PATH}/lib64:${ADMIRE_PATH}/lib:$LD_LIBRARY_PATH
export PATH=$PATH:${ADMIRE_PATH}/iodeps/bin

# Temporary directory for computation
export TMP_PATH=$TMPDIR
echo DIRECTORY $TMPDIR
# GekkoFS mount point (can be any directory)
export GKFS_MNT=/dev/shm/rnou

# Persistent storage for GekkoFS data
export GKFS_ROOT="${TMP_PATH}/agkfs_root"

# Shared file for available servers

# GekkoFS logging and configuration
export GKFS_DAEMON_LOG_LEVEL=0
export LIBGKFS_LOG_OUTPUT=${HOME}/test/clients_lithops.txt
export LIBGKFS_LOG=info
export LIBGKFS_LOG_SYSCALL_FILTER=epoll_wait,epoll_create,epoll_ctl
export GKFS_DAEMON_LOG_PATH=${HOME}/test/servers_lithops.txt
export LIBGKFS_NUM_REPL=0

# GekkoFS daemon and library paths
export GKFS_DAEMON="${ADMIRE_PATH}/bin/gkfs_daemon"
export GKFS_PROXY="${ADMIRE_PATH}/bin/gkfs_proxy"
export GKFS="${ADMIRE_PATH}/lib64/libgkfs_intercept.so"
export GKFS_LIBC="${ADMIRE_PATH}/lib64/libgkfs_libc_intercept.so"


#export OMPI_MCA_osc=sm
#export OMPI_MCA_pml=ob1
#export OMPI_MCA_pml=ucx
#export OMPI_MCA_btl=self 
#export OMPI_MCA_osc=ucx
#export OMPI_MCA_coll=^hcoll,ml

# Configuration
IOR_EXE=/home/bsc/bsc025015/ADMIRE/io500/bin/ior           # Path to IOR executable
OUTPUT_DIR=$GKFS_MNT/io500 # Set your output directory
FILE_PREFIX="${OUTPUT_DIR}/testfile"
RESULTS="/home/bsc/bsc025015/experiments/gpfs/ior_results.csv"
NODE_LIST=(${SLURM_JOB_NUM_NODES})
SIZE_LIST=("1024M" "2048M" "4G" "8G" "16G" "32G" "64G" "128G" "256G" "512G")      # Total file sizes to test
TRANSFER_SIZE="512K" 
#export FI_UNIVERSE_SIZE=16000
# Ensure output directory exists

# Initialize results file (only once)
if [ ! -f "$RESULTS" ]; then
    echo "Timestamp,Nodes,Size,Write_Avg(MiB/s),Write_Max(MiB/s),Read_Avg(MiB/s),Read_Max(MiB/s)" > $RESULTS
fi

# Get current timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
export GKFS_HOSTS_FILE=${HOME}/test/gkfs_hosts.txt
export LIBGKFS_HOSTS_FILE=${HOME}/test/gkfs_hosts.txt

# Launch GekkoFS Daemon
export LIBGKFS_LOG=none
COMM="-P ofi+verbs"
# COMM="-P ucx+all"
CMD1="${GKFS_DAEMON} --mountdir=${GKFS_MNT:?} --rootdir=${GKFS_ROOT:?} $COMM -l ib0 -c"
CMD2="${GKFS_PROXY} -p ofi+sockets -H ${LIBGKFS_HOSTS_FILE}"

# the next exports makes all non working
#export SLURM_CPU_BIND=none

unset I_MPI_PMI_LIBRARY
export I_MPI_JOB_RESPECT_PROCESS_PLACEMENT=0

srun \
    -n ${SLURM_JOB_NUM_NODES:?} \
    -N ${SLURM_JOB_NUM_NODES:?} \
    bash -c "rm -rf ${TMP_PATH} ; mkdir -p ${GKFS_MNT} ${GKFS_ROOT}"

echo "Starting GEKKOFS_DAEMON " $SLURM_JOB_NUM_NODES " : " $CMD1
GEKKO=${SLURM_JOB_NUM_NODES}
srun \
    -N $GEKKO \
    -n $GEKKO  \
    -c 112 --overlap --overcommit --mem=0 \
    --export="ALL" --oversubscribe \
    /bin/bash -c "${CMD1}" &

touch $LIBGKFS_HOSTS_FILE

sleep 5
while true; do
    # Check the number of lines in the file
    LINE_COUNT=$(wc -l < "$LIBGKFS_HOSTS_FILE")

    # Print the current line count for debugging

    # Check if the line count is 30
    if [ $LINE_COUNT -ge ${GEKKO} ]; then
        echo "Servers started"
        break
    fi

    # Wait for a short period before checking again
    sleep 1
done

#srun \
#        -N $GEKKO \
#    -n $GEKKO  \
#    -c 112 --overlap --overcommit --mem=0 \
#    --export="ALL" --oversubscribe \
#    /bin/bash -c "${CMD2}" &



./io500.sh myconfig_gekko.ini



srun -n ${SLURM_JOB_NUM_NODES:?} -N ${SLURM_JOB_NUM_NODES:?} -c 1 --mem=0 --oversubscribe --export="ALL" /bin/bash -c "rm -rf ${TMP_PATH}/*; pkill --signal SIGINT gkfs_daemon ; rm -rf ${GKFS_MNT}"


