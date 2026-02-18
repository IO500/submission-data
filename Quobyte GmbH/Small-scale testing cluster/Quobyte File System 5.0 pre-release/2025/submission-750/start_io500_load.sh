#!/bin/bash

pushd "${IO500_WORKDIR:-/home/io500}"
./io500.sh quobyte.ini &> /dev/null && echo OK || echo FAILURE
popd
