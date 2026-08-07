import paramiko, os

LOCAL = r'E:\wxshadow\work'
REMOTE = '/home/zzc/mkpms/kpms/wxshadow'

files = [
    'wxshadow.c', 'wxshadow.h', 'wxshadow_bp.c', 'wxshadow_handlers.c',
    'wxshadow_internal.h', 'wxshadow_pgtable.c', 'wxshadow_scan.c',
]

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('192.168.229.128', username='zzc', password='zzc')

# Figure out where the sources actually live on the VM.
for cmd in ['ls /home/zzc/mkpms/kpms/wxshadow/ 2>/dev/null | head; echo ---; find /home/zzc/mkpms -maxdepth 3 -name wxshadow.c 2>/dev/null']:
    print('===', cmd)
    _, stdout, _ = c.exec_command(cmd)
    print(stdout.read().decode('utf-8', 'replace'))

s = c.open_sftp()

# Resolve remote dir from find output.
_, stdout, _ = c.exec_command('find /home/zzc/mkpms -maxdepth 3 -name wxshadow.c 2>/dev/null | head -1')
path = stdout.read().decode().strip()
if not path:
    print('ERROR: could not locate wxshadow.c on VM')
    c.close(); raise SystemExit(1)
remote_dir = os.path.dirname(path)
print('remote dir =', remote_dir)

for f in files:
    local = os.path.join(LOCAL, f)
    remote = remote_dir + '/' + f
    s.put(local, remote)
    print('uploaded', f, '->', remote)

s.close(); c.close()
print('done')
