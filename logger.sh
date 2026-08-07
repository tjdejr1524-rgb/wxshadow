#!/system/bin/sh
rm -f /data/local/tmp/crash.log
dmesg -w | grep --line-buffered -iE 'wxshadow|kpatch|panic|oops|unable to handle|bug:|call trace|internal error|pgtable|translation|severe' > /data/local/tmp/crash.log 2>&1
