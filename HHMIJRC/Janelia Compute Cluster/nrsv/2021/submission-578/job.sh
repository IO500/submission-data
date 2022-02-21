bsub -q test -R "span[ptile=36]" -n 2520 -J '25Gb-nrsv-70n36p-std' mpirun -np 2520 -ppn 36 ./io500 ./config-hhmi.ini --mode=extended

