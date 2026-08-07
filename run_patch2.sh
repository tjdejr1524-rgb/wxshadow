#!/system/bin/sh
# SAFE patch test: patch the "mov x0,#0x5a5a" at target_func+0x64 (addr 0x400738)
# with "mov x0,#0x1111" so the constant becomes 0x5A5A1111 instead of 0x5A5A5A5A.
# Expected acc = sum(1..8=0x24) + 0x5A5A1111 = 0x5a5a1135
# (we patch the mov at +0x64; movk at +0x68 still sets the high half to 0x5a5a)
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "parsed PID=$PID"
# patch addr = 0x4006d4 + 0x64 = 0x400738
PATCH_ADDR=0x400738

# mov x0, #0x1111 = 0xD2822220, LE bytes 20 22 82 d2 -> hex "202282d2"
/data/local/tmp/wxshadow_client -p $PID -a $PATCH_ADDR --patch 202282d2
echo "client rc=$?"

touch /data/local/tmp/bptest_go
wait $BPTEST_BG
echo "=== bptest output (expect acc=5a5a1135) ==="
cat /data/local/tmp/bptest_out.log
