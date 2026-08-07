#!/system/bin/sh
# Register-modification test: set bp with -r x0=0x100, verify acc changes.
# target_func returns a+b+...+h + 0x5A5A5A5A. With i=1: 1+2+3+4+5+6+7+8=0x24.
# If x0 is forced to 0x100 at BRK (replacing 1), acc = 0x100+2+3+4+5+6+7+8 + 0x5A5A5A5A
#   = 0x100 + 0x23 + 0x5A5A5A5A = 0x129 + 0x5A5A5A5A = 0x5a5a5b83
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "parsed PID=$PID ADDR=$ADDR"

# Set bp WITH register modification: force x0=0x100
/data/local/tmp/wxshadow_client -p $PID -a $ADDR -r x0=0x100
echo "client rc=$?"

touch /data/local/tmp/bptest_go
wait $BPTEST_BG
echo "=== bptest output (expect acc=5a5a5b83) ==="
cat /data/local/tmp/bptest_out.log
