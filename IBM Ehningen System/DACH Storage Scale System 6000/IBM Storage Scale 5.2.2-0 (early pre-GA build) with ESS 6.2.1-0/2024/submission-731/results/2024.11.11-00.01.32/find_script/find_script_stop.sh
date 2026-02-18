#export PATH=/usr/lib64/mpich/bin:/usr/lpp/mmfs/bin:/home/mpich/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#export PATH=/nshare/pidsouza/mpich-4.1/install/bin:$PATH
#export PATH=/usr/mpi/gcc/openmpi-4.1.5a1/bin/:$PATH
export PATH=/nshare/pidsouza/mpich/install/bin:$PATH

DATA_DIR=$1
TIMESTAMP_FILE=$3
#echo ${DATA_DIR} ${TIMESTAMP_FILE} >> /tmp/j5

#copy find_script under io500 directory, and modify the below locations:
IO500_DIR="/home/pidsouza/io500_mnt/SC24_Atlanta/io500/"
HOST_FILE="/home/pidsouza/io500_mnt/SC24_Atlanta/io500/host.list"
PROCS=150

SCRIPT_DIR="${IO500_DIR}/find_script"
OUTPUT_FILE="/tmp/pfind.out"

${SCRIPT_DIR}/ssh_script.sh 19 ${SCRIPT_DIR} ${HOST_FILE} &

#io500.sh external script invocation passes all required arguments to external script. However, doe to parsing issue with *01* had to hardcode some of the args for pfind
/usr/bin/time -p mpiexec -np ${PROCS} -f ${HOST_FILE} ${IO500_DIR}/bin/pfind ${DATA_DIR} -newer ${TIMESTAMP_FILE} -size 3901c -name *01* -C -q 10000 >${OUTPUT_FILE} 2>&1

${SCRIPT_DIR}/ssh_script.sh 18 ${SCRIPT_DIR} ${HOST_FILE} &

cat ${OUTPUT_FILE} >> ${OUTPUT_FILE}.fix1.out &     # This step is not required. Test purpose only
# grep operation should be at the end for it to output the results back to the caller io500.sh
grep MATCHED ${OUTPUT_FILE}
