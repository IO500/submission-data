#!/bin/bash

# IO500 was run interactively via salloc. The following includes the commands (see output for actual output and config file contents)

# Shell 1 (Start GekkoFS)
~/gekkofs/scripts/run/gkfs -c ~/run/io500/gkfs_io500_proxy_sockets.conf -f -v start

# Shell 2 (Run IO500)
~/run/io500/io500 $ ./io500.sh config_gkfs_isc24.ini
