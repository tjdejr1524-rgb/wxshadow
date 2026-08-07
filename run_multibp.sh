#!/system/bin/sh
# Multi-breakpoint test: set 2 breakpoints on the same page (target_func at 0x4006d4
# and target_func+0x64 = 0x400738, both on page 0x400000). Run bptest count=5, verify
# BOTH breakpoints are hit and the process completes.
set -e
rm -f /data/local/tmp/bptest_go /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 5 > /data/local/tmp/bptest_out.log 2>&1 &
BG=$!
sleep 1
PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
BP2_ADDR=0x400738   # target_func+0x64, same page
echo "PID=$PID bp1=$ADDR bp2=$BP2_ADDR"

/data/local/tmp/wxshadow_client -p $PID -a $ADDR
/data/local/tmp/wxshadow_client -p $PID -a $BP2_ADDR
echo "both bps set"

touch /data/local/tmp/bptest_go
wait $BG 2>/dev/null
echo "=== bptest output ==="
tail -2 /data/local/tmp/bptest_out.log
