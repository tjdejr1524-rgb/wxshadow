import paramiko, os
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('192.168.229.128', username='zzc', password='zzc')
s = c.open_sftp()
# upload + cross-compile gup_reader.c statically
s.put(r'E:\wxshadow\work\gup_reader.c', '/tmp/gup_reader.c')
s.close()
_, so, se = c.exec_command('aarch64-linux-gnu-gcc -static -o /tmp/gup_reader /tmp/gup_reader.c 2>&1 && ls -la /tmp/gup_reader')
print(so.read().decode('utf-8','replace'))
err = se.read().decode('utf-8','replace')
if err: print('ERR:', err)
# pull back
s = c.open_sftp()
s.get('/tmp/gup_reader', r'E:\wxshadow\work\gup_reader')
s.close()
c.close()
print('done')
