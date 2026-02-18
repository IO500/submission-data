set -x

LOG=logs-UltraLX-echo-clients-panfs10-isc23-3runs

mkdir $LOG

module use --append /net/nfs.paneast.panasas.com/perfcore/modulefiles/rhel_8_amd64/
module load mpi/mpich-3.3.2 hdf5/hdf5-1.14.0 io500/io500-isc23


for i in 10  
do    

	mkdir ${LOG}/${i}
	for s in 8 8 8  
	do 
		N=$((${i}*${s})) 
 		echo client count: $i total threads: $N Final Log:${LOG}/${i}
		mpiexec -f hosts/$i -n $N  -envall io500 io500-config.pgh-realm-75-4.ini 
	done
	mv ../result_dir/202* ${LOG}/${i}/  
done 


