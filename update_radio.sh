#!/bin/sh
# this file must be in the same directory as the dhcpd.leases file (typically /var/lib/dhcpd/) and 
# have the same owner and permissions
# this does the heavy lifting of modifying the radio
# it uses sshpass, which must be installed and ssh to authenticate into the radio and dowload two files
# and execute the initialize.sh script.
# remove sshpass -p your_password_here if you use Certificate authentication
sshpass -p your_password_here ssh -o StrictHostKeyChecking=no your_user_here@$1 <<'ENDSSH'
arch=`echo $PS1 | cut -d '.' -f 1`
tftp -g -r Ubiquiti/initialize.sh -l /tmp/initialize.sh your_tftp_server_here
tftp -g -r Ubiquiti/$arch/initialize.cfg -l /tmp/initialize.cfg your_tftp_server_here
sleep 1
/bin/sh /tmp/initialize.sh
ENDSSH
exit 0