#!/bin/bash
mpiexec -np 320 -H 10.0.1.114:32,10.0.1.90:32,10.0.1.92:32,10.0.1.94:32,10.0.1.96:32,10.0.1.98:32,10.0.1.100:32,10.0.1.108:32,10.0.1.110:32,10.0.1.112:32 --mca btl_tcp_if_include eth0 --allow-run-as-root /root/io500/io500 /root/io500/config-full.ini
