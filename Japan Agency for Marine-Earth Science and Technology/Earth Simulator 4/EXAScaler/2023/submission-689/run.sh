#!/bin/bash

#PBS -q ve_S
#PBS -T intmpi
#PBS -b 10
#PBS -B 0:JSV=1027
#PBS -B 1:JSV=1036
#PBS -B 2:JSV=1045
#PBS -B 3:JSV=1054
#PBS -B 4:JSV=1063
#PBS -B 5:JSV=1072
#PBS -B 6:JSV=1081
#PBS -B 7:JSV=1090
#PBS -B 8:JSV=1099
#PBS -B 9:JSV=1108
#PBS -r n
#PBS -l elapstim_req=02:00:00
#PBS --custom vesetnum-lhost=8
#PBS --cpunum_lhost=64
#PBS --memsz_lhost=125gb
#PBS -N io500_10vh
##PBS -M sample@jamstec.go.jp
##PBS -v NMPI_PROGINF=YES     # set "ALL"/"DETAIL"/"ALL_DETAIL" for more detailed output

module load Intel_oneAPI/2021.1.1/all IntelMPI/2021.1.1

cd ${PBS_O_WORKDIR}
./io500.sh config-io500-work.ini
