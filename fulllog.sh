#!/system/bin/sh
rm -f /data/local/tmp/full.log
dmesg -w > /data/local/tmp/full.log 2>&1
