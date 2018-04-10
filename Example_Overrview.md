~~~
                                                                                              +----------------------------------------------+
Example Network                                                                               |                    Router                    |
  DHCP Server and VLAN 51 gateway can not be same machine                                     |eth0   uplink to internet                     |
                                                              +------------------------------->eth1   VLAN 1 192.168.2.1/24, 192.168.3.1/24  |
                                                              |   +--------------------------->eth2   gateway for VLAN 50  10.250.0.1/24     |  VLAN 50 has a ip helper-address of 192.168.3.10/24
Main Network VLAN 1                                           |   |   +----------------------->eth3   gateway for VLAN-51  192.168.105.1/24  |  VLAN 51 has no ip helper-address
   Internert Gateway interface any                            |   |   |                       +----------------------------------------------+
   Radio DHCP interface 192.168.3.10/24                       |   |   |       This port has native vlan 51 or access 51
   Customer Equipment DHCP interface 192.168.2.10/24          |   |   |
                                                      +-------+-+-+-+-+-+-------------------------------+
VLAN 50 - Customer Side Radio Network                 |   1   3 | 5 | 7 | 9  11  13  15  17  19  21  23 |
                                                      |         |   |   |       Switch                  |
  Subnet 10.250.0.0/24                                | Access 1| 50| 51| Trunk Ports 50,51 Native 50   |
    Gateway 10.250.0.1                                |         |   |   |     For Radios                |
                                                      |   2   4 | 6 | 8 |10  12  14  16  18  20  22  24 |
VLAN 51 - Customer Equipment Network                  +---+---+-+---+-----------------------------------+
                                                          |   |
  Subnet 192.168.105.0/24                                 |   |
    Gateway 192.168.105.1                                 |   |
                                                          |   |                                +---------------------------------------+
                                                          |   |                                |              DHCP Server              |
                                                          |   +--------------------------------> eth0 Radio DHCP 192.168.3.10          |
                                                          +------------------------------------> eth1 Customer Equip DHCP 192.168.2.10 |
                                                                                               +---------------------------------------+

~~~
