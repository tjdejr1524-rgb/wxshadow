#!/system/bin/sh
# Read-hiding test: set a BRK breakpoint at target_func (installs shadow page with
# BRK #0x7 instruction). Then another process reads the instruction bytes at the
# bp address via /proc/PID/mem. With read-hiding ENABLED, the reader should see
# the ORIGINAL instruction (ff 03 01 d1 = sub sp,sp,#0x40), NOT the BRK (00 00 20 d4).
#
# BRK #0x7 = 0xD4200000, LE bytes = 00 00 20 d4
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 100 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "target PID=$PID ADDR=$ADDR"

# Arm breakpoint (installs shadow page with BRK at ADDR)
/data/local/tmp/wxshadow_client -p $PID -a $ADDR
echo "bp client rc=$?"

# Now read the 4 bytes at ADDR via /proc/PID/mem from THIS (other) process.
echo "=== reading 4 bytes at $ADDR via /proc/$PID/mem (expect ff0301d1 = original) ==="
dd if=/proc/$PID/mem bs=1 skip=$((ADDR)) count=4 2>/dev/null | xxd

# Also read via process_vm_readv-style (cat /proc/PID/mem with offset)
echo "=== hexdump via xxd at offset $ADDR ==="
xxd -s $ADDR -l 4 /proc/$PID/mem 2>/dev/null

# Cleanup: release the breakpoint so bptest can finish its 100 iters cleanly
/data/local/tmp/wxshadow_client -p $PID --release
echo "release rc=$?"

# Let bptest finish
touch /data/local/tmp/bptest_go
wait $BPTEST_BG 2>/dev/null
echo "=== bptest done ==="
tail -2 /data/local/tmp/bptest_out.log
