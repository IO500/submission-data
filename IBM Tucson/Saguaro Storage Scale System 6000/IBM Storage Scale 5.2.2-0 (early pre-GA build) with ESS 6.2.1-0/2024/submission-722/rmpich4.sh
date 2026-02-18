#!/usr/bin/bash
#export PATH=/usr/lib64/mpich/bin:/usr/lpp/mmfs/bin:/home/mpich/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
#export PATH=/nshare/pidsouza/mpich-4.1/install/bin:$PATH
set -x
rm -f /tmp/stopjob /tmp/stopjobr
FS_NAME=fs1
NCLASS="nc1"
NCLASS352="s6k2bib,s6k2aib"

#mmchfs ${FS_NAME} --inode-limit 500M:500M
PROCS=200

IO500_DIR=/nshare/ess_regression/ess6000/io500_isc24
RESULT_DIR=${IO500_DIR}/IO500_results
CLIENT_HOST=${IO500_DIR}/nodesib.10
INI_FILE="ess6000_config.ini"
#INI_FILE="ess6000_config_ior-hard-write.ini"

check_fs_mount()
{
  echo "Checking ${FS_NAME} mount status"
  mount|grep ${FS_NAME}
  RET=`echo $?`
  if [ $RET == 0 ]
  then
    touch /gpfs/${FS_NAME}/up
  else
    echo "FS not mounted ... exit"
    exit
  fi
  mmshutdown -a;sleep 10;mmstartup -a;sleep 60
  while [ 1 ]; do 
  mount|grep ${FS_NAME}
  RET=`echo $?`
  if [ $RET == 0 ]
  then
  if [ -f "/gpfs/${FS_NAME}/up" ]
  then
     echo "File exist"
     break
  else 
     sleep 5
  fi
  else
    echo "FS not mounted ... wait"
    sleep 5
  fi
  done # while 1
  sleep 60
}

fs_delete_format_create_2BB()
{
  IO_SERVER="e351aib"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_2BB.sh 1 2 35"
  #Create new FS
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_2BBv3.sh 8M 8+2p 1 2 e35"
}

fs_delete_format_create_1BB()
{
  IO_SERVER="e351aib"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_1BB.sh 35 35"
  #Create new FS
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_1BBv3.sh 8M 8+2p 35  e35"
}

:<<'BLOCK_FS_RECREATE'
fs_delete_create_2BB()
{
  IO_SERVER="e351aib"
  #ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_woformat_2BB.sh 1 2 35"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_2BB.sh 1 2 35"
  #Create new FS
  #ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_2BB.sh 8M 8+2p 1 2 e35"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_2BBv2.sh 8M 8+2p 1 2 e35"
}

fs_delete_create_1BB()
{
  IO_SERVER="e351aib"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_1BB.sh 1 35"
  #Create new FS
  #ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_2BB.sh 8M 8+2p 1 2 e35"
  #ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_2BBv2.sh 8M 8+2p 1 2 e35"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_1BB.sh 8M 8+2p 1 e35"
}
BLOCK_FS_RECREATE

:<<'CBLOCK'
##########
  fs_delete_format_create_2BB
  #fs_delete_create_2BB
  check_fs_mount
  mmgetstate -aL
##########
CBLOCK

mmchnode --nomanager -N client
mmchnode --manager -N ${CLIENT_HOST}
mmmount ${FS_NAME} -N ${CLIENT_HOST}
mmlscluster
mmgetstate -aL
mmlsconfig
mmlsfs ${FS_NAME}
mmdf ${FS_NAME}
mmlsmount ${FS_NAME} -L
mmdsh -N all uptime
mmdsh -N all "mmdiag --version"
mmdsh -N ${NCLASS} "nvme list"
#mmdsh -N ${NCLASS352} "nvme list"
mmdsh -N all "ibv_devinfo"
mmdsh -N all "lscpu;numactl -H"
mmdsh -N all "tuned-adm active"
:<<'BLK'
#echo 999|mmchconfig dataShipAssertOnFailure=yes -i -N ${CLIENT_HOST}
#echo 999|mmchconfig dataShipAssertOnFailure=yes -i -N ${NCLASS}
#echo 999|mmchconfig dataShipAssertOnFailure=yes -i -N ${NCLASS352}
mmchconfig preferDesignatedMnode=yes -i -N ${CLIENT_HOST}
mmchconfig preferDesignatedMnode=yes -i -N ${NCLASS}
mmchconfig preferDesignatedMnode=yes -i -N ${NCLASS352}
# autoCompact=yes[default], fgdlTokenBatchAcquire=0[default]
echo 999|mmchconfig autoCompactDir=no -N ${CLIENT_HOST} -i
echo 999|mmchconfig autoCompactDir=no -N ${NCLASS} -i
echo 999|mmchconfig autoCompactDir=no -N ${NCLASS352} -i
echo 999|mmchconfig fgdlTokenBatchAcquire=yes -N ${CLIENT_HOST} -i
echo 999|mmchconfig fgdlTokenBatchAcquire=yes -N ${NCLASS} -i
echo 999|mmchconfig fgdlTokenBatchAcquire=yes -N ${NCLASS352} -i
BLK

#mmchconfig fsyncIsGlobal=no -i
#mmchconfig fsyncIsGlobal=yes -i
#mmchconfig nBucketGroups=1024  #requires mmfsd restart

:<<'ALLOW'
PPN=20
echo 999|mmchconfig allowFullblockRead=0 -i
echo 999|mmchconfig allowSuperstrideRead=1 -i
echo 999|mmchconfig tasksPerNode=${PPN} -i
#mmchconfig prefetchAggressivenessRead=0 -i
mmchconfig prefetchAggressivenessRead=default -i
ALLOW

:<<'BLK_DS'
mmchconfig dataShipClientBuffersPerServer=100,dataShipMaxServerThreads=delete,dataShipServerBufferPct=delete -i -N ${CLIENT_HOST}
mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=10 -i -N ${NCLASS}
mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=10 -i -N ${NCLASS352}
BLK_DS
:<<'BLK_DSS'
mmchconfig dataShipClientBuffersPerServer=50,dataShipMaxServerThreads=delete,dataShipServerBufferPct=50 -i -N ${CLIENT_HOST}
mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=10 -i -N ${NCLASS}
mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=10 -i -N ${NCLASS352}
BLK_DSS

sleep 5
mmdsh -N ${CLIENT_HOST} mmfsadm dump config|egrep "fgdlTokenBatchAcquire|autoCompactDir|dirPreSplitLevels|preferDesignatedMnode|avoidDirFragments|pagepool|fgdlActivityTimeWindow|fgdlAggressiveDirblockSplit|deferNegativeDcacheInvalidation|fgdlAggressiveDirblockSplitThreshold|verbsRdmaWriteFlush|inodePrefetchThreshold|maxFilesToCache|maxStatCache" -w
mmdsh -N ${NCLASS} mmfsadm dump config|egrep "dirPreSplitLevels|preferDesignatedMnode|avoidDirFragments|pagepool|fgdlActivityTimeWindow|fgdlAggressiveDirblockSplit|deferNegativeDcacheInvalidation|fgdlAggressiveDirblockSplitThreshold|verbsRdmaWriteFlush|inodePrefetchThreshold|maxFilesToCache|maxStatCache" -w
#mmdsh -N ${NCLASS352} mmfsadm dump config|egrep "dirPreSplitLevels|preferDesignatedMnode|avoidDirFragments|pagepool|fgdlActivityTimeWindow|fgdlAggressiveDirblockSplit|deferNegativeDcacheInvalidation|fgdlAggressiveDirblockSplitThreshold|verbsRdmaWriteFlush|inodePrefetchThreshold|maxFilesToCache|maxStatCache" -w

mmdsh -N all /usr/lpp/mmfs/bin/mmfsadm dump config|egrep "prefetchAggressiveness|allowFullblockRead|allowSuperstrideRead|tasksPerNode|prefetchThreads|prefetchPartitions"

/usr/lpp/mmfs/bin/mmtracectl --set --trace=def --tracedev-write-mode=overwrite --tracedev-overwrite-buffer-size=12G --trace-recycle=off -N all

#server
mmdsh -N ${NCLASS} mmdiag --config|egrep -w "ignorePrefetchLUNCount|maxFilesToCache|maxMBpS|maxReceiverThreads|maxStatCache|nsdMaxWorkerThreads|nsdMinWorkerThreads|nsdSmallThreadRatio|numaMemoryInterleave|pagepool|workerThreads|verbsPorts"
#mmdsh -N ${NCLASS352} mmdiag --config|egrep -w "ignorePrefetchLUNCount|maxFilesToCache|maxMBpS|maxReceiverThreads|maxStatCache|nsdMaxWorkerThreads|nsdMinWorkerThreads|nsdSmallThreadRatio|numaMemoryInterleave|pagepool|workerThreads|verbsPorts"

#client
mmdsh -N ${CLIENT_HOST} mmdiag --config|egrep -w "ignorePrefetchLUNCount|maxblocksize|maxFilesToCache|maxMBpS|maxStatCache|numaMemoryInterleave|pagepool|workerTureads|verbsPorts"
#exit

#for i in {1..5}
#for i in {1..3}
for i in 1
#while :
do

#ssh s6k2aib "/root/perf/config/recreate.sh"
#sleep 120
#df -h /gpfs/fs1

:<<'BLK'
BLK
#Start the inode prefetch script
#Kill any existing tracker
ps -eaf|grep track_io500|grep -v grep|awk '{print $2}'|xargs kill -9
${IO500_DIR}/find_script/track_io500.sh ${RESULT_DIR} >> ./inodeprefetch_tracker.log 2>&1 &
#${IO500_DIR}/find_script/trace_mdt_hard_stat.sh ${RESULT_DIR} >> ./trace_tracker.log 2>&1 &

#./io500.sh config-full_FG_CS-EHW_Hint_Write_find_delete.ini
echo "Embedded pfind Iter $i"
#./io500.sh config-full_FG_CS_Hint.ini # config with finegrainread/write and createsharing hints(wo external find script)
./io500.sh ${INI_FILE} ${CLIENT_HOST} ${PROCS} # config with finegrainread/write and createsharing hints(wo external find script)
#echo "External pfind Iter $i"
#./io500.sh config-full_FG_CS-EHW_Hint_extfind.ini # config with finegrainread/write and createsharing hints(with external find script)
sleep 5

  if [[ -f /tmp/stopjob ]] ; then
    echo "Found /tmp/stopjob.  Exiting."
    exit 1
  fi

######################
:<<'BLK'
  ssh e351aib.gpfs.net mmreclaimspace ${FS_NAME} --reclaim-threshold 0
  sleep 1200
BLK

:<<'BLK'
  #fs_delete_create_2BB
  fs_delete_create_1BB
  check_fs_mount
  echo "New FS created or mmreclaimspace done"
BLK
######################

  #Delete the FS and format the drives and sleep for 600s(10min)
:<<'BLKD'
      # 1BB RW portion start
  IO_SERVER="ess3500rw2a"
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/delete_1BB.sh 2 35"
  #Create new FS
  ssh ${IO_SERVER} "/nshare/pidsouza/bin/create_1BB.sh 8M 8+2p 2 e35"
# 1BB RW portion end

#  fs_delete_format_create_2BB
  fs_delete_format_create_1BB
BLKD

:<<'BLKT'
      # 2BB RF+RW portion start

  fs_delete_format_create_2BB
  #fs_delete_create_2BB
  check_fs_mount
  echo "New FS created"
  # 2BB RF+RW portion end
BLKT

  mmgetstate -aL 
  mmumount ${FS_NAME} -a
  sleep 10
  mmmount ${FS_NAME} -a
  sleep 10

  if [[ -f /tmp/stopjobr ]] ; then
    echo "Found /tmp/stopjobr.  Exiting."
    exit 1
  fi

done

#mmchconfig preferDesignatedMnode=delete -i -N ${CLIENT_HOST}
#mmchconfig preferDesignatedMnode=delete -i -N ${NCLASS}
#mmchconfig preferDesignatedMnode=delete -i -N ${NCLASS352}
#echo 999|mmchconfig autoCompactDir=yes -N ${CLIENT_HOST} -i
#echo 999|mmchconfig autoCompactDir=yes -N ${NCLASS} -i
#echo 999|mmchconfig autoCompactDir=yes -N ${NCLASS352} -i
#echo 999|mmchconfig fgdlTokenBatchAcquire=no -N ${CLIENT_HOST} -i
#echo 999|mmchconfig fgdlTokenBatchAcquire=no -N ${NCLASS} -i
#echo 999|mmchconfig fgdlTokenBatchAcquire=no -N ${NCLASS352} -i
#mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=delete -i -N ${CLIENT_HOST}
#mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=delete -i -N ${NCLASS}
#mmchconfig dataShipClientBuffersPerServer=delete,dataShipMaxServerThreads=delete,dataShipServerBufferPct=delete -i -N ${NCLASS352}
#mmchconfig fsyncIsGlobal=no -i
#mmchconfig autoCompactDir=no -i
#mmchconfig nBucketGroups=1024  #requires mmfsd restart
