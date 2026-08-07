#!/system/bin/sh
# Fork-protection test: arm BRK at target_func in parent. Parent runs a few iters
# (hits BRK, captured), then forks. Child runs N iters of target_func and should
# NOT hit the BRK (shadow page not inherited due to fork protection). Child exits
# cleanly with status=0.
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/forktest_out.log

/data/local/tmp/forktest --paused --fork 3 > /data/local/tmp/forktest_out.log 2>&1 &
FT_BG=$!
sleep 1

PID=$(sed -n 's/^forktest pid=\([0-9]*\)/\1/p' /data/local/tmp/forktest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/forktest_out.log)
echo "target PID=$PID ADDR=$ADDR"

# Arm breakpoint in parent
/data/local/tmp/wxshadow_client -p $PID -a $ADDR
echo "bp client rc=$?"

# Release parent so it runs 3 iters (hitting BRK 3x) then forks
touch /data/local/tmp/bptest_go
wait $FT_BG
echo "forktest exit=$?"
echo "=== forktest output ==="
cat /data/local/tmp/forktest_out.log
