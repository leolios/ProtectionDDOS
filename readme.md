# DDOSProtection

Commandes à utilisé une fois le sysctl.conf configuré

Plus un dernier tweak :

echo 'options nf_conntrack hashsize=500000' > /etc/modprobe.d/nf_conntrack.conf # (Calculate your own values ! depending on your hardware)
mais qui nécessite un reboot pour être appliquée, donc on le place directement :

echo 500000 > /sys/module/nf_conntrack/parameters/hashsize
Vous pouvez alors appliquer ces modifications ainsi :

sysctl -p
