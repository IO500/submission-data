#!/bin/bash

export I_MPI_FABRICS=shm:dapl
export I_MPI_FALLBACK=tcp
export I_MPI_DEBUG=0
export I_MPI_ROOT=/misc/local/INTEL-2018/compilers_and_libraries_2018.0.128/linux/mpi
export DAT_OVERRIDE=/misc/local/admin/cx5_dat.conf

mpirun -np 1248 -ppn 26 -f hostfile-48-mix ./io500 config-hhmi.ini

