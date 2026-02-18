SIGNAL=$1
SCRIPT_DIR="/nshare/pidsouza/io500/monthly/ISC2023_04212023/io500/find_script"
for i in `cat /nshare/pidsouza/io500/monthly/122022/nodes`
do
ssh $i ${SCRIPT_DIR}/stop_cont_io500.sh ${SIGNAL} &
done
