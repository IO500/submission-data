#!/bin/bash

mpirun -np 160 --allow-run-as-root --hostfile hosts.ibm /nvme/gpfs-benchmarks/io500/io500 0917-8m-ibm-config.ini


