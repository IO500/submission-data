#!/bin/sh
#PBS -q miyabitest-g1
##PBS -q regular-g
#PBS -W group_list=gz02
#PBS -l select=10:mpiprocs=64
##PBS -l ompthreads=N
   
cd $PBS_O_WORKDIR

module purge
module load gcc ompi singularity
./io500-10n-s.sh config-10n-s.ini
