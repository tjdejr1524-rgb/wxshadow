import paramiko
c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect('192.168.229.128', username='zzc', password='zzc')
s = c.open_sftp()
s.get('/home/zzc/mkpms/build2/kpms/wxshadow/wxshadow.kpm', 'E:/wxshadow/work/wxshadow.kpm')
s.get('/home/zzc/mkpms/build2/kpms/wxshadow/wxshadow_client', 'E:/wxshadow/work/wxshadow_client')
print('downloaded artifacts')
s.close(); c.close()
