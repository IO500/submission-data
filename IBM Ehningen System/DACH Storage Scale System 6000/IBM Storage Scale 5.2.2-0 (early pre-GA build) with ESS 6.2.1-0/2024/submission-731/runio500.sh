#!/bin/bash
/home/pidsouza/io500_mnt/SC24_Atlanta/io500/find_script/track_io500.sh /home/pidsouza/io500_mnt/SC24_Atlanta/io500/results_bb8nvme_8M.extPFIND > /home/pidsouza/io500_mnt/SC24_Atlanta/io500/find_script/inodeprefetch_tracker.log 2>&1 &

bash -x ./io500.jl.sh config_withFGWS_extFIND_FGRS.jl.bb8.ini
