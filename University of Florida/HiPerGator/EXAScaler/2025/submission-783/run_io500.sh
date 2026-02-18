#! /bin/bash
module load gcc openmpi
LD_LIBRARY_PATH=/apps/mpi/gcc/14.2.0/openmpi/5.0.7/lib/openmpi:/apps/mpi/gcc/14.2.0/openmpi/5.0.7/lib:/opt/slurm/lib64:/apps/compilers/gcc/14.2.0/lib64:/opt/mellanox/hcoll/lib::
cd local/src/io500
bash ./io500-10x192-blue2-24mount-turin-smt.sh config-10x192-blue2-24mount-turin-smt.ini
