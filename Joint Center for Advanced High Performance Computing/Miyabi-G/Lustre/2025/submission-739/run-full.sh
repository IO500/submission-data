#!/bin/sh
#PBS -q miyabitest-g
##PBS -q regular-g
#PBS -W group_list=gz02
#PBS -l select=192:mpiprocs=10
##PBS -l ompthreads=N
   
cd $PBS_O_WORKDIR

module purge
module load gcc ompi singularity
./io500-full.sh config-full.ini 
