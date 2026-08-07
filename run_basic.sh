#!/system/bin/sh
# Basic closed-loop BRK/step test. Usage: run_basic.sh
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

# Start bptest paused in background, capture its PID+addr
/data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

# Parse PID and target_func address from its output
PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "parsed PID=$PID ADDR=$ADDR"

# Arm breakpoint via client
/data/local/tmp/wxshadow_client -p $PID -a $ADDR
echo "client rc=$?"

# Release bptest
touch /data/local/tmp/bptest_go

# Wait for bptest to finish
wait $BPTEST_BG
echo "bptest exit=$?"
echo "=== bptest output ==="
cat /data/local/tmp/bptest_out.log
