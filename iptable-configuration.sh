#!/bin/bash
# Script béta test pour faire des réglages dans iptable.

iptables -A INPUT -i lo -j ACCEPT                                      # Autoriser les flux en localhost
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT # Autoriser les connexions déjà établies,
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT                   # Autoriser SSH,
iptables -A INPUT -p tcp -m tcp --dport http -j ACCEPT                 # Autoriser HTTP,
iptables -A INPUT -p tcp -m tcp --dport https -j ACCEPT                # Autoriser HTTPS,
iptables -P INPUT DROP                                                 # Politique par défaut de la table INPUT : DROP. (i.e bloquer tout le reste).
iptables -P FORWARD DROP                                               # On est pas un routeur ou un NAT pour un réseau privé, on ne forward pas de paquet.

# We can simply use following command to enable logging in iptables.
iptables -A INPUT -j LOG

# We can also define the source ip or range for which log will be created.
iptables -A INPUT -s 192.168.10.0/24 -j LOG

#To define level of LOG generated by iptables us –log-level followed by level number.
iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-level 4

#We can also add some prefix in generated Logs, So it will be easy to search for logs in a huge file.
iptables -A INPUT -s 192.168.10.0/24 -j LOG --log-prefix '** SUSPECT **'

tail -f /var/log/kern.log

apt-get install iptables-persistent
iptables-save > /etc/iptables/rules.v4
