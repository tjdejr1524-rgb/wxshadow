import paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('192.168.229.128', username='zzc', password='zzc')
cmds = [
    'cd /home/zzc/mkpms && rm -rf build2 && mkdir build2',
    'cd /home/zzc/mkpms/build2 && cmake -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc -DKP_DIR=/home/zzc/mkpms .. 2>&1 | tail -15',
    'cd /home/zzc/mkpms/build2 && make wxshadow.kpm wxshadow_client -j4 2>&1 | tail -70',
    'ls -la /home/zzc/mkpms/build2/kpms/wxshadow/ && file /home/zzc/mkpms/build2/kpms/wxshadow/wxshadow.kpm',
]
for cmd in cmds:
    print('===', cmd)
    stdin, stdout, stderr = c.exec_command(cmd)
    out = stdout.read().decode('utf-8', 'replace')
    err = stderr.read().decode('utf-8', 'replace')
    if out: print(out)
    if err: print('STDERR:', err)
c.close()
