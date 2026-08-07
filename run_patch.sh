#!/system/bin/sh
# Patch test: patch target_func entry with "mov x0, #0x42" (0xd2800000 | (0x42<<5) = 0xd2800840)
# Actually: mov x0, #0x42 = 0xD2800840 (sf=1, opc=10, hw=00, imm16=0x0042, Rd=0)
# Verify: with x0 forced to 0x42, acc = 0x42 + (2+3+4+5+6+7+8=0x23) + 0x5A5A5A5A
#        = 0x65 + 0x5A5A5A5A = 0x5a5a5abf
# We patch WITHOUT setting a bp first (patch writes shadow page directly).
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "parsed PID=$PID ADDR=$ADDR"

# Patch target_func entry with mov x0, #0x42 = 0xD2800840
# In memory (LE) bytes: 40 08 80 d2 -> hex string "400880d2"
# Verify: with x0 forced to 0x42, acc = 0x42 + (2+3+4+5+6+7+8=0x23) + 0x5A5A5A5A
#        = 0x65 + 0x5A5A5A5A = 0x5a5a5abf
# We patch WITHOUT setting a bp first (patch writes shadow page directly).
set -e
rm -f /data/local/tmp/bptest_go
rm -f /data/local/tmp/bptest_out.log

/data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
BPTEST_BG=$!
sleep 1

PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
echo "parsed PID=$PID ADDR=$ADDR"

# mov x0, #0x42 (0xD2800840), LE bytes 40 08 80 d2
/data/local/tmp/wxshadow_client -p $PID -a $ADDR --patch 400880d2
echo "client rc=$?"

touch /data/local/tmp/bptest_go
wait $BPTEST_BG
echo "=== bptest output (expect acc=5a5a5abf) ==="
cat /data/local/tmp/bptest_out.log
