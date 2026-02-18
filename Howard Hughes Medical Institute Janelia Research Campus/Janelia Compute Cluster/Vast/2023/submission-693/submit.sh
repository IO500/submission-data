bsub -app io500 -q io500_parallel -n2048 -J '100Gb-nrsv-32n2048p-rdma-16' mpirun -n 2048 ./io500 ./config-hhmi.ini
