# DDOSProtection


Change Iptables LOG File Name
-----------------------------

To change iptables log file name edit /etc/rsyslog.conf file and add following configuration in file.

`vi /etc/syslog.conf`

Add the following line

`kern.warning /var/log/iptables.log`

Now, restart rsyslog service using the following command.

`service rsyslog restart`
