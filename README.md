# mikrotik-route53
Mikrotik DNS update script for route53 with external script

Disclaimer: I know it's shitty code but it works for me! Send a PR if you find a bug.

## Add the script to your router
```
/system scheduler add interval=1m name=R53DNS on-event="/system script run r53dns\r\n" policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive
/system script add comment="Updates the DNS through a ruby script" name=r53dns owner=admin policy=read,write,policy source="[...from mikrotik.txt...]
```

## Script to execute the change
You can run the ruby script with supervisor or WEBrick. 

```
[program:r53change]
command=/usr/bin/ruby /srv/r53ipchange/r53ip.rb
process_name=%(program_name)s
directory=/tmp
umask=022
stopsignal=QUIT
user=nobody
redirect_stderr=true
stdout_logfile=/var/log/r53ip.log
stdout_logfile_maxbytes=1MB
stdout_capture_maxbytes=1MB
```
