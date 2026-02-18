bsub -app io500 -q io500_parallel -n 2048 -J '100Gb-prfs-32n64' mpirun -n 2048 ./io500 ./config-hhmi.ini
