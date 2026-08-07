#!/system/bin/sh
# GUP-hiding test: set BRK at target_func (installs shadow page with BRK), then
# use process_vm_readv (via gup_reader) to read 4 bytes at the bp addr from
# another process. With GUP-hiding ENABLED (follow_page_pte hooked), the reader
# should see the ORIGINAL instruction (ff0301d1), NOT the BRK (000020d4).
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 100 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "target PID=$PID ADDR=$ADDR"

# Arm breakpoint
/data/local/tmp/wxshadow_client -p $PID -a $ADDR
echo "bp client rc=$?"

# Read via process_vm_readv (GUP path -> follow_page_pte)
echo "=== process_vm_readv read (expect ff 03 01 d1 = original) ==="
/data/local/tmp/gup_reader $PID $ADDR

# Cleanup
/data/local/tmp/wxshadow_client -p $PID --release
echo "release rc=$?"
touch /data/local/tmp/bptest_go
wait $BPTEST_BG 2>/dev/null
echo "=== bptest done ==="
tail -1 /data/local/tmp/bptest_out.log
