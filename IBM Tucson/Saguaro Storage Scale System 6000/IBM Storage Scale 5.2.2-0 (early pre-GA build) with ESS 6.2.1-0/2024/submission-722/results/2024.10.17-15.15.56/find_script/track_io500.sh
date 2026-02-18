#!/usr/bin/bash

## script to track the progress of io500
## and disable inodePrefetchThreshold during
## the find benchamrk

## result.txt will be tracked
echo "$(date) - Starting inodePrefetch tracking script"
RESULT_DIR=$1

#initial sleep for io500 to kickstart
sleep 60

WRK_DIR=`ls -1 -t ${RESULT_DIR}|grep 2024|grep -v tgz|head -1`
#WRK_DIR=$(ls -td -- ${RESULT_DIR}/* | head -n 1)
echo ${RESULT_DIR}/${WRK_DIR}
#echo $WRK_DIR

# file to track
RESULT_FILE="${RESULT_DIR}/${WRK_DIR}/result.txt"
#RESULT_FILE="${WRK_DIR}/result.txt"
echo $RESULT_FILE

# look out for
mdtest_hard_write='\[mdtest-hard-write\]'
find='\[find\]'
ior_easy_read='\[ior-easy-read\]'

disable_inodePrefetchThreshold () {
    date
    echo 999 | mmchconfig inodePrefetchThreshold=2000000 -i
    sleep 5s
    mmfsadm dump config | grep inodePrefetchThreshold
    printf "Disable complete\n"
    date
}

enable_inodePrefetchThreshold () {
    date
    echo 999 | mmchconfig inodePrefetchThreshold=5 -i
    sleep 5s
    mmfsadm dump config | grep inodePrefetchThreshold
    printf "Enable complete\n"
    date
}

tail -fn 0 $RESULT_FILE | while read line; do
    if echo "$line" | grep -qE '\[.*?\]'; then
        printf "%s workload started ... \n" "$line"
    fi
    if echo "$line" | grep -qE "$find"; then
	    printf "Disabling inodePrefetchThreshold\n"
	    disable_inodePrefetchThreshold
    fi
    if echo "$line" | grep -qE "$ior_easy_read"; then
        printf "enabling inodePrefetchThreshold\n"
        enable_inodePrefetchThreshold
        break
    fi
done
