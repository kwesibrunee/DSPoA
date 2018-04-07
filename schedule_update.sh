#!/bin/sh
# this file must be in the same directory as the dhcpd.leases file (typically /var/lib/dhcpd/) and 
# have the same owner and permissions
# modifiy path below as necessary
# SELINUX if available will need to either be configured or in PERMISSIVE mode for this to work
# uses the at command to schedule an update for 5 seconds in the future, to give the radio a chance to apply its 
# dhcp supplied ip and be available for ssh.
at now  <<ENDCMD
sleep 5
/bin/sh /var/lib/dhcpd/update_radio.sh $1
ENDCMD