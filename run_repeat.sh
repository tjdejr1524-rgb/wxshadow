#!/system/bin/sh
# Bounded repeat: run basic BRK/step loop N times in one module-load session.
# Each iter: fresh bptest, set bp, run 1 iter, verify acc=5a5a5a7e, release.
# Usage: sh run_repeat.sh <N>
N=${1:-10}
PASS=0
FAIL=0
echo "=== repeat basic loop $N times ==="
for i in $(seq 1 $N); do
    rm -f /data/local/tmp/bptest_go /data/local/tmp/bptest_out.log
    /data/local/tmp/bptest --paused --count 1 > /data/local/tmp/bptest_out.log 2>&1 &
    BG=$!
    sleep 0.5
    PID=$(sed -n 's/^bptest pid=\([0-9]*\)/\1/p' /data/local/tmp/bptest_out.log)
    ADDR=$(sed -n 's/^target_func = \(0x[0-9a-f]*\)/\1/p' /data/local/tmp/bptest_out.log)
    /data/local/tmp/wxshadow_client -p $PID -a $ADDR >/dev/null 2>&1
    touch /data/local/tmp/bptest_go
    wait $BG 2>/dev/null
    ACC=$(sed -n 's/.*acc=\([0-9a-f]*\).*/\1/p' /data/local/tmp/bptest_out.log | tail -1)
    /data/local/tmp/wxshadow_client -p $PID --release >/dev/null 2>&1
    if [ "$ACC" = "5a5a5a7e" ]; then
        PASS=$((PASS+1))
        printf "iter %3d: PASS acc=%s\n" "$i" "$ACC"
    else
        FAIL=$((FAIL+1))
        printf "iter %3d: FAIL acc=%s (want 5a5a5a7e)\n" "$i" "$ACC"
    fi
done
echo "=== RESULT: $PASS/$N passed, $FAIL failed ==="
