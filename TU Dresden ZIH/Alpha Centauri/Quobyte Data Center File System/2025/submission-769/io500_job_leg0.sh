#!/usr/bin/bash -l
#SBATCH --job-name="qtest-io500"
#SBATCH --account=p_vendortest
#SBATCH --partition=alpha
#SBATCH --nodes=10
#SBATCH --mem 0
#SBATCH --exclusive
#SBATCH --output=logs/load/io500-leg0-%j.out
#SBATCH --error=logs/load/io500-leg0-%j.err
#SBATCH --export=NONE
#SBATCH --time=4:00:00
#SBATCH --cpu-freq=Performance
#SBATCH --ntasks-per-node=17
#SBATCH --reservation=io500
#SBATCH --gres=gpu:8
#SBATCH --cpus-per-gpu=6

unset SLURM_EXPORT_ENV


MOUNT_POINT="/tmp/quobyte_mnt"
QIO500_OPTS="--cpu-bind=verbose"
QCLIENT_CONFIG_FILE="$HOME/etc/client-service_leg0.cfg"

export MOUNT_POINT QIO500_OPTS QCLIENT_CONFIG_FILE

srun -m cyclic --overlap -n "$SLURM_JOB_NUM_NODES" ./mount_wrapper.sh &
srun -m cyclic --overlap -n "$SLURM_JOB_NUM_NODES" ./mount_checker.sh

pushd "$MOUNT_POINT/io500/runtime"
./io500.sh quobyte.ini
popd
srun -m cyclic --overlap -n "$SLURM_JOB_NUM_NODES" ./mount_wrapper.sh end
