#!/usr/bin/env bash
#SBATCH -N 10
#SBATCH -n 400
#SBATCH -q special
#SBATCH -p orion
#SBATCH -A admin
#SBATCH -t 2:00:00

CONFIG_FILE="$SLURM_SUBMIT_DIR/orion_data2.ini"

srun "$SLURM_SUBMIT_DIR/io500" "$CONFIG_FILE"
