#!/bin/bash
#SBATCH --ntasks-per-node=85
#SBATCH -p parallel
#SBATCH -A hpc_build
#SBATCH --nodelist=udc-ba02-[5-9]c[0-1]
#SBATCH --reservation=io500
#SBATCH --job-name=IO-500
#SBATCH --time=03:30:00
#SBATCH -o io_500_out_%J
#SBATCH -e io_500_err_%J
#SBATCH --dependency=singleton

module load gcc/11.4.0 mvapich2/2.3.7
srun ./io500 myconfig.ini
