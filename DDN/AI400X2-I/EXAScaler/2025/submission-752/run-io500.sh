#!/bin/bash
#SBATCH -p src
#SBATCH --nodes=10
#SBATCH --ntasks-per-node=128
#SBATCH -o io_500_out_%j
#SBATCH -e io_500_err_%J
#SBATCH --overcommit

PATH=/usr/mpi/gcc/openmpi-4.1.7rc1/bin:$PATH

#sleep 600
#./myio500.sh myio500.ini
./myio500.sh myio500-x3.ini
