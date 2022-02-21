#!/bin/bash
bsub -q test -R "span[ptile=32]" -n 320 -J '100Gb-weka-10n32p' -app sharedscratch mpirun -n 320 ./io500 ./config-hhmi.ini
