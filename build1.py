import paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('192.168.229.128', username='zzc', password='zzc')
cmds = [
    'which aarch64-linux-gnu-gcc cmake ninja',
    'cd /home/zzc/mkpms && ls -la && cat CMakeLists.txt | head -50',
    'cd /home/zzc/mkpms && rm -rf build && mkdir build',
    'cd /home/zzc/mkpms/build && cmake .. 2>&1 | tail -40',
]
for cmd in cmds:
    print('===', cmd)
    stdin, stdout, stderr = c.exec_command(cmd)
    out = stdout.read().decode('utf-8', 'replace')
    err = stderr.read().decode('utf-8', 'replace')
    if out: print(out)
    if err: print('STDERR:', err)
c.close()
