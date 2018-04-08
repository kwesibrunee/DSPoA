Docsis Style Provisioning over AirMax

Using this provisioning method, will allow you to control whether radios will pass customer traffic, based on how they are added to the dhcp server. The motivation for this setup is to make provisioning AirMax radios similar to provisioning a Docsis CM, as that is what I am most familiar with.

Goals / Features

* Provision customer radios using only DHCP
* Works with M and AC radios (tested with 8.5.1-cs and 6.1.6-cs)
* Installer only needs to concern himself with getting the radio talking to AP, all other settings are applied when he sets the management interface to dhcp
* Standardize the config using templates at intial setup and during each dhcp renew (speeds only)
* Secure SSH (Certificate based SSH only)
* Radio only works as a bridge and only if it is authorized
* if radio is not authorized in dhcp radio will not pass customer traffic on initial setup or when radios lease expires/radio is reboot.
* use DHCP option 82 to determine what radio a customer is behind, this information will be available in dhcpd.leases file.
* use 1 vlan for management and one for customer data
* set maxcpe (customer devices plugged into radio) to 1 
* allow to classify radios via dhcp
* allow for customized templates for each family of radios WA, XW etc...
* updates the hostname of the radio on dhcp lease/renew


Future Goals
* use IP Source Guard on Cisco switches to prevent customers from statically assigning ips this would require an on_commit script for pool where modified radios exist
* after install only read-only access to Web Gui, with ability to Temp enable for changes 
* Switch to an all dhcp on_commit based solution to work with any firmware version.
* write tutorial to run dhcpd on edgerouter, and gateway on second edgerouter

Caveats
* only works with -CS firmware, but with SSH (password) disabled and Read Only access to the Radio Gui should mitigate all security problems
* any setting set in initialize.cfg for a specific architecture will override the setting on the radio, be very careful setting any radio / wireless specific settings as the radio may not reconnect to tower. Additionally during initialize.sh before the merge of the files settings beginning with bridge,ebtables,netconf,tshaper and vlan will be removed from current running config of radio before the merge, this is because depending on the radio's status before initialize.sh is ran some values would not be overridden by the initialize.cfg resulting in a radio that did not work right. This makes it possible to upgrade already configured radios as well as new installs.
* this method requires the radio to reboot 3-4 times during setup
* requires on-commit functionality of dhcp server, i.e. dhcpd Cisco CNR etc...
* dhcp server and gateway for radios/clients cannot be on the same device
* does not use Option 82 built into the firmware, so gui will always show it disabled though it is actually enabled.
* SSH to the radios will only be possible from devices that have the private key that corresponds to the public key in the config 
* WDS must be enabled on M radios for dhcp-fwd to work.


Procedural overview

* Radio Install begins like any other, Installer mounts the Radio, aligns/assigns the radio to an AP. After the Installer is satisfied with the Radio's alignment, he proceeds to the network tab where he changes the IP setting from static to DHCP
* From this point on, the provisioning system takes over
*   During first DHCP discover the DHCP server detects an un-modified radio and assigns it an ip from a special pool, when an IP from this pool is assigned, an on_commit script triggers a modification script to load the correct custom scripts to make the process work.
*       This modification script does two things, downloads an initialization script and an architecture specific config templates
*           The initialization script creates several files in the /etc/persistent directory and an rc.prestart script to be run on next boot. 
*           It also merges the /tmp/system.cfg and the architecture specific initialize.cfg file, performs a save/reboot
*   After Rebooting the rc.prestart script modifies udhcpc's behavior to send a custom Client identifier such as "Ubiquiti", it also links several files from /etc/persistent to their normal locations
*       the DHCP server recoginizes this and assigns the radio an ip from a different pool
*       after the radio recieves it's lease it does 3 things
*           downloads a Speed config file from a tftp server using parameters received from DHCP it merges this speed config with /tmp/system.cfg and if different save and reboot
*           configures dhcp-fwd with the ip address it received from the dhcp server and restarts dhcp-fwd with new settings
*           updates its hostname kernel parameter with hostname value it received from hostname parameter in dhcp server
*       customer equipment attempting to dhcp will use the br1 (wlan0.51, eth0) and its dhcp requests will be intercepted by dhcp-fwd and unicasted on br0 (wlan0 (native vlan 50)) to the dhcp server responses will be unicast back to br0 where they will be broadcast back to customer equipment.

In order to use this setup you will need to adjust:

* VLAN settings to match your network in the initialize.cfg file for each architecture (netconf.4.devname, bridge.2.port.1.devname, ebtables.sys.arpnat.2.devname, ebtables.sys.vlan.1.id, vlan.1.id)
* update all initialize.cfg files UNMS key with yours (unms.uri)
* create a SSH public/private key see OPENSSH docs for instructions
* update all initialize.cfg files ssh public key with yours (sshd.auth.key.1.value)
* update all initialize.cfg files RO username, password with yours (users.2.name, users.2.password (encrypted, grab from existing radio config))
* update all initialize.cfg files RW username, password with yours (users.2.name, users.2.password (encrypted, grab from existing radio config))
* update all initialize.cfg files update_radio.sh with RW username and unencrypted password to update the radio
* update initialize.sh with the DHCP server ip for Clients to connect to. 
* update SETUP_DHCPD file with values for your network. Copy relevant config to dhcpd config file.
* copy Ubiquiti folder to your tftp directory typically /tftpboot/
* optionally create a key for OMAPI use to dhcpd look online for a tutorial
