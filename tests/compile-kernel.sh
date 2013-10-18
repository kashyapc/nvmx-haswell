#!/bin/bash
set -x

make defconfig

cd /home/test/src/linux

for i in {1..10}; do
        make clean;
        sync;
        sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
        time make -j7;
done 2>&1 | tee defconfig-kernel-make-timings-$(date +"%m-%d-%Y-%T").txt


