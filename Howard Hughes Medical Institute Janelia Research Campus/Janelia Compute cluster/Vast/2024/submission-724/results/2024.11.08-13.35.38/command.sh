bsub -app io500 -q io500_parallel -n 640 -J '100Gb-prfs-10n64' mpirun -n 640 ./io500 ./config-hhmi.ini
