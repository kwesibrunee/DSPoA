#!/bin/sh
# this is the initial setup script


# update the init scripts
# put them in /tmp initially 
#/usr/bin/tee /etc/persistent/rc.presysinit <<'EOF' > /dev/null
#EOF
#/usr/bin/tee /etc/persistent/rc.postsysinit <<'EOF' > /dev/null
#EOF
/usr/bin/tee /etc/persistent/rc.prestart <<'EOF' > /dev/null
#!/bin/sh
# Link the following files from /etc/persistent
# /etc/dhcp-fwd.conf
# /etc/sysinit/restart-dhcp-fwd.conf
# /etc/sysinit/apply-config.conf
# /etc/sysinit/update-hostname.conf

# if dhcp-fwd.conf exists link it to its home
if [ -e /etc/persistent/dhcp-fwd.conf ]; then
    /usr/bin/cp /etc/persistent/dhcp-fwd.conf /etc/dhcp-fwd.conf
fi
if [ -e /etc/persistent/restart-dhcp-fwd.conf ]; then
    /usr/bin/cp /etc/persistent/restart-dhcp-fwd.conf /etc/sysinit/restart-dhcp-fwd.conf
fi
if [ -e /etc/persistent/apply-config.conf ]; then
    /usr/bin/cp /etc/persistent/apply-config.conf /etc/sysinit/apply-config.conf
fi
if [ -e /etc/persistent/update-hostname.conf ]; then
    /usr/bin/cp /etc/persistent/update-hostname.conf /etc/sysinit/update-hostname.conf
fi

# update /etc/inittab to:
# start udhcpc with the exta flag -V Ubiquiti
# start dhcp-fwd

chkudhcpc=`grep udhcpc /etc/inittab | grep "V" | wc -l`
if [ $chkudhcpc -lt 1 ]; then
    sed -i '/udhcpc/ s/$/ -V Ubiquiti/' /etc/inittab
fi

# add dhcp-fwd to inittab if not present
chkfwd=`grep -q dhcp-fwd /etc/inittab | wc -l`
if [ $chkfwd -lt 1 ]; then
    echo "null::respawn:/usr/bin/dhcp-fwd -n -c /etc/dhcp-fwd.conf" >> /etc/inittab
fi
#restart init
/usr/bin/init -q
# start maxcpe script
/etc/persistent/maxcpe.sh &

# add services that are to be run at dhcp lease/renewal
/usr/bin/echo -e 'restart-dhcp-fwd' >> /etc/udhcpc_services
/usr/bin/echo -e 'apply-config' >> /etc/udhcpc_services
/usr/bin/echo -e 'update-hostname' >> /etc/udhcpc_services
# modify udhcpc script to start_services on renew)
udhcpc_replacement_string="renew)\n                udhcpc_start_services"
export udhcpc_replacement_string
sed -i "s/renew)/$udhcpc_replacement_string/" /etc/udhcpc/udhcpc
# restart udhcpc to make sure new settings take effect
/usr/bin/killall -9 udhcpc
EOF
# make rc.prestart executable
chmod 755 /etc/persistent/rc.prestart
#/usr/bin/tee /etc/persistent/rc.poststart <<'EOF' > /dev/null
#EOF
#/usr/bin/tee /etc/persistent/rc.prestop <<'EOF' > /dev/null
#EOF
#/usr/bin/tee /etc/persistent/rc.poststop <<'EOF' > /dev/null
#EOF

/usr/bin/tee /etc/persistent/update-hostname.conf <<'EOF' > /dev/null
plugin_start() {
	export hostname
        echo $hostname > /proc/sys/kernel/hostname	
	true
}
plugin_stop() {
	true
}
EOF

/usr/bin/tee /etc/persistent/restart-dhcp-fwd.conf <<'EOF' > /dev/null
plugin_start() {
	/usr/bin/sed -ir "s/^name[[:space:]]*br1[[:space:]].*$/name    br1     `cat /sys/class/net/br1/address | sed -r 's/://g'`/" /etc/dhcp-fwd.conf
	export ip
        /usr/bin/sed -ir "s/^ip[[:space:]]*br1[[:space:]].*/ip      br1     $ip/" /etc/dhcp-fwd.conf
        /usr/bin/killall -9 dhcp-fwd
        true
}
plugin_stop() {
        true
}
EOF
/usr/bin/tee /etc/persistent/maxcpe.sh <<'EOF' > /dev/nul
until brctl showmacs br1 | grep -E '2[[:space:]]+[a-z0-9][a-z0-9]:.*:[a-z0-9][a-z0-9][[:space:]]no' | cut -d$'\t' -f 2 | grep -m 1 :; do sleep 1 ; done
MAC=`brctl showmacs br1 | grep -E '2[[:space:]]+[a-z0-9][a-z0-9]:.*:[a-z0-9][a-z0-9][[:space:]]no' | cut -d$'\t' -f 2`
export MAC
ebtables -F FORWARD
ebtables -A FORWARD -s $MAC -i eth0 -j ACCEPT
ebtables -A FORWARD -i eth0 -j DROP
EOF
chmod 755 /etc/persistent/maxcpe.sh
/usr/bin/tee /etc/persistent/apply-config.conf <<'EOF' > /dev/null
plugin_start() {
    # download the config file script if $boot_file and $siaddr are set
    if [ -n $boot_file ]; then
        if [ -n $siaddr ]; then
                #arch=`cat /etc/version | cut -d '.' -f 1` ; export arch
                #/usr/bin/tftp -g -r Ubiquiti/$arch/$boot_file -l /tmp/new.cfg $siaddr
		usr/bin/tftp -g -r Ubiquiti/$boot_file -l /tmp/new.cfg $siaddr
        fi
    fi
    # make sure /tmp/new.cfg exists
    if [ -e /tmp/new.cfg ]; then
        #compare downloaded config with system.cfg and adjust as needed
        cp /tmp/new.cfg /tmp/new1.cfg
        /usr/bin/awk -F= '!a[$1]++' /tmp/new.cfg /tmp/system.cfg > /tmp/merged.cfg
        /usr/bin/sort -u /tmp/merged.cfg > /tmp/sorted_merged.cfg
        #compare a sorted system.cfg to merged.cfg
        /usr/bin/sort -u /tmp/system.cfg > /tmp/sorted_system.cfg
        /usr/bin/diff /tmp/sorted_merged.cfg /tmp/sorted_system.cfg
        RETVAL=$?
        # if there is a diff move to system.cfg save and reboot
        if [ $RETVAL != 0 ]; then
            mv /tmp/sorted_merged.cfg /tmp/system.cfg
            #save
            /usr/bin/cfgmtd -w -p /etc/
            #reboot
            /usr/etc/rc.d/rc.softrestart save
            reboot -d 10
        fi
        # if no changes delete /tmp files
        rm /tmp/new*.cfg
        rm /tmp/merged.cfg
        rm /tmp/sorted_merged.cfg
        rm /tmp/sorted_system.cfg
    fi
    true
}
plugin_stop() {
    true
}
EOF
/usr/bin/tee /etc/persistent/dhcp-fwd.conf <<'EOF' > /dev/null
pidfile /var/run/dhcp-fwd.pid
logfile /var/log/dhcp-fwd.log
loglevel        0

if      br1     true false true
if      br0     false true true
server  ip      192.168.2.10   br0
name    br1     _mac_
ip      br1     _ip_
EOF



#initialize commands
#process initial config
#remove any lines from config that start with: bridge, ebtables, vlan, netconf, tshaper
/usr/bin/sed '/^bridge\|ebtables\|netconf\|tshaper\|vlan/d' /tmp/system.cfg > /tmp/system_temp.cfg
# combine two files if entry exists in both use entry from first file
/usr/bin/awk -F= '!a[$1]++' /tmp/initialize.cfg /tmp/system_temp.cfg > /tmp/merged.cfg
# sort the output
/usr/bin/sort -u /tmp/merged.cfg > /tmp/sorted_merged.cfg
# sort the current system.cfg
/usr/bin/sort -u /tmp/system.cfg > /tmp/sorted_system.cfg
#compare a sorted system.cfg to merged.cfg
/usr/bin/diff /tmp/sorted_merged.cfg /tmp/sorted_system.cfg
# if they are different use the combined one
RETVAL=$?
if [ $RETVAL != 0 ]; then
    mv /tmp/sorted_merged.cfg /tmp/system.cfg
fi
#save
/usr/bin/cfgmtd -w -p /etc/
#reboot
/usr/etc/rc.d/rc.softrestart save
# sometimes softrestart doesn't actually reboot the radio so if we get to the next line force a reboot 
reboot -d 10
