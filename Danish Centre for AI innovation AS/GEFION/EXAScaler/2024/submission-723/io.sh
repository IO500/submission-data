#!/bin/bash -x
#SBATCH --job-name=io500
#SBATCH --time=0-04:00:00
#SBATCH --partition=defq
#SBATCH --ntasks-per-node=112
#SBATCH --nodes=10
#SBATCH --nodelist=dgx010,dgx011,dgx030,dgx031,dgx070,dgx071,dgx100,dgx101,dgx130,dgx131
#SBATCH --exclusive

#hpcx_dir="/opt/hpcx/hpcx-v2.20-gcc-mlnx_ofed-redhat9-cuda12-x86_64"
#source "$hpcx_dir/hpcx-init-ompi.sh"
#hpcx_load

#module load openmpi/gcc/64/4.1.5

#export OMPI_MCA_btl_openib_allow_ib=1
#export OMPI_MCA_btl_openib_if_include="mlx5_1:1,mlx5_7:1"
#export UCX_NET_DEVICES=mlx5_1:1,mlx5_7:1
#
#lctl set_param osc.*.max_dirty_mb=2000
#lctl set_param osc.*.checksums=0
#lctl set_param osc.*.short_io_bytes=65536
#lctl set_param osc.*.max_pages_per_rpc=16M
#lctl set_param ldlm.namespaces.*.lru_size=0
#lctl set_param ldlm.namespaces.*.lru_max_age=1000
#lctl set_param mdc.*.max_rpcs_in_flight=128
#lctl set_param llite.*.max_cached_mb=65536

/home1/fbrunkhorst/io500-new/io500/io500-ddn.sh config-ddn-mt.ini
