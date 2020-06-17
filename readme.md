# DDOSProtection

### IPtables Tables

Filter: The filter table is the default and most commonly used table that rules go to if you don't use the -t (--table) option.

NAT: This table is used for Network Address Translation (NAT). If a packet creates a new connection, the nat table gets checked for rules.

Mangle: The mangle table is used to modify or mark packets and their header information.

Raw: This table's purpose is mainly to exclude certain packets from connection tracking using the NOTRACK target.

As you can see there are four different tables on an average Linux system that doesn't have non-standard kernel modules loaded. Each of these tables supports a different set of iptables *chains*.

### IPtables Chains

PREROUTING: raw, nat, mangle

-   Applies to packets that enter the network interface card (NIC)

INPUT: filter, mangle

-   Applies to packets destined to a local socket

FORWARD: filter, mangle

-   Applies to packets that are being routed through the server

OUTPUT: raw, filter, nat, mangle

-   Applies to packets that the server sends (locally generated)

POSTROUTING: nat, mangle

-   Applies to packets that leave the server

Change Iptables LOG File Name
-----------------------------

To change iptables log file name edit /etc/rsyslog.conf file and add following configuration in file.

`vi /etc/syslog.conf`

Add the following line

`kern.warning /var/log/iptables.log`

Now, restart rsyslog service using the following command.

`service rsyslog restart`
