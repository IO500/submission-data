SIGNAL=$1
SCRIPT_DIR=$2
HOST_FILE=$3
for i in `cat ${HOST_FILE}`
do
ssh $i ${SCRIPT_DIR}/stop_cont_io500.sh ${SIGNAL} &
done
