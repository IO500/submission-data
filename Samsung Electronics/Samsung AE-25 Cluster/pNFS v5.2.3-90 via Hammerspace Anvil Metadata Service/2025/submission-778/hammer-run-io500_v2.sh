#!/bin/bash
# hammer-run-io500_v3.sh
# Usage: ./hammer-run-io500_v3.sh <PPN>

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <PPN>"
  exit 1
fi

i=$1                     # Processes per node (PPN)
C=10                     # Number of client nodes
N=$((C * i))             # Total MPI ranks

MPI=$(which mpirun)
IO500=/root/workspace/io500/io500
CONFIG=/mnt/hammerspace/io500/config-test.ini
LOG_DIR="logs-io500"
LOG="${LOG_DIR}/${C}-clients-${i}_SAMSUNG"

mkdir -p "$LOG_DIR"

echo "------------------------------------------------------------"
echo " Starting IO500 run"
echo " Clients: $C"
echo " PPN: $i"
echo " Total ranks: $N"
echo " Log: $LOG"
echo "------------------------------------------------------------"

# Example RDMA tuning — uncomment if needed
# echo "ensuring rdma_slot_table_entries=32 - Clients"
# pdsh -w 172.16.18.[41-50] "echo 32 > /proc/sys/sunrpc/rdma_slot_table_entries" > /dev/null 2>&1

CMD="${MPI} -np ${N} -mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1 \
  --map-by ppr:${i}:node \
  --hostfile hosts/${C} \
  --allow-run-as-root --oversubscribe \
  ${IO500} ${CONFIG}"

echo "Running: $CMD" | tee -a "$LOG"
eval "$CMD" | tee -a "$LOG"

echo "------------------------------------------------------------"
echo "Waiting for cleanup and cache clear..."
sleep 1200s

# Drop caches
pdsh -w 172.16.18.[41-50] "echo 3 > /proc/sys/vm/drop_caches" > /dev/null 2>&1
pdsh -w serviceadmin@172.16.12.[145-152,213,214] "echo 3 > /proc/sys/vm/drop_caches" > /dev/null 2>&1
echo "Cleanup complete."

