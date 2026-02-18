#! /bin/bash

# Parse arguments
config_file=$1
benchmark_dir=$2

# Check if required arguments are provided
if [ -z "$config_file" ] || [ -z "$benchmark_dir" ]; then
    echo "Usage: $0 <config_file> <benchmark_dir>"
    exit 1
fi

# IO500_MPIARGS="--hostfile /etc/mpi/hostfile_21_node -np 410 -env HYDRA_BINDING_POLICY scatter  -env LD_PRELOAD /usr/local/lib/libdarshan.so"

# Use the environment variable passed from Python
cd $benchmark_dir
echo "MPIARGS: "$IO500_MPIARGS
# if "debug" is in the config file name, then add -verbosity 10
if [[ $config_file == *"debug"* ]]; then
    mpirun $IO500_MPIARGS ./io500 $config_file -v=10
else
    mpirun $IO500_MPIARGS ./io500 $config_file
fi