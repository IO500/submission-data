#!/bin/bash
#SBATCH --nodes=256
#SBATCH --ntasks=1024
#SBATCH --ntasks-per-node=4
#SBATCH --mem=240G
#SBATCH --partition=admin
#SBATCH --job-name=io500
#SBATCH --account=admin
#SBATCH --time=02:00:00
#SBATCH --reservation=Maintenance_2024Q1
#SBATCH --nodelist=cns[001-270]

# Load Env
module load mpi/openmpi/4.1.3

# IO500
cd /gpfs/home/axians/ralix/io500/io500-io500-sc23
./io500.sh ../cenaero_256nodes.ini

