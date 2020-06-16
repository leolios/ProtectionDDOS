#!/bin/bash
# Script béta test pour faire des réglages dans iptable.

iptables -A INPUT -i lo -j ACCEPT                                      # Autoriser les flux en localhost
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT # Autoriser les connexions déjà établies,
iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT                   # Autoriser SSH,
iptables -A INPUT -p tcp -m tcp --dport http -j ACCEPT                 # Autoriser HTTP,
iptables -A INPUT -p tcp -m tcp --dport https -j ACCEPT                # Autoriser HTTPS,
iptables -P INPUT DROP                                                 # Politique par défaut de la table INPUT : DROP. (i.e bloquer tout le reste).
iptables -P FORWARD DROP                                               # On est pas un routeur ou un NAT pour un réseau privé, on ne forward pas de paquet.

apt-get install iptables-persistent
iptables-save > /etc/iptables/rules.v4

*mangle
# paquet avec SYN et FIN à la fois
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
# paquet avec SYN et RST à la fois
-A PREROUTING -p tcp -m tcp --tcp-flags SYN,RST SYN,RST -j DROP
# paquet avec FIN et RST à la fois
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,RST FIN,RST -j DROP
# paquet avec FIN mais sans ACK
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,ACK FIN -j DROP
# paquet avec URG mais sans ACK
-A PREROUTING -p tcp -m tcp --tcp-flags ACK,URG URG -j DROP
# paquet avec PSH mais sans ACK
-A PREROUTING -p tcp -m tcp --tcp-flags PSH,ACK PSH -j DROP
# paquet avec tous les flags à 1 <=> XMAS scan dans Nmap
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
# paquet avec tous les flags à 0 <=> Null scan dans Nmap
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
# paquet avec FIN,PSH, et URG mais sans SYN, RST ou ACK
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,PSH,URG -j DROP
# paquet avec FIN,SYN,PSH,URG mais sans ACK ou RST
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,PSH,URG -j DROP
# paquet avec FIN,SYN,RST,ACK,URG à 1 mais pas PSH
-A PREROUTING -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,ACK,URG -j DROP

*mangle
-A PREROUTING -s 224.0.0.0/8 -j DROP
-A PREROUTING -s 169.254.0.0/16 -j DROP
-A PREROUTING -s 172.16.0.0/12 -j DROP
-A PREROUTING -s 192.0.2.0/24 -j DROP
-A PREROUTING -s 192.168.0.0/16 -j DROP
-A PREROUTING -s 10.0.0.0/8 -j DROP
-A PREROUTING -s 0.0.0.0/8 -j DROP
-A PREROUTING -s 240.0.0.0/5 -j DROP
-A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP


*filter
-A INPUT -m state --state INVALID -j DROP

*raw
# 1. en -t raw, les paquets TCP avec le flag SYN à destination des ports 22,80 ou 443 ne seront pas suivi par le connexion tracker (et donc traités plus rapidement)
-A PREROUTING -i eth0 -p tcp -m multiport --dports 22,80,443 -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j CT --notrack

*filter
# 2. en input-filter, les paquets TCP avec le flag SYN à destination des ports 22,80 ou 443 non suivi (UNTRACKED ou INVALID) et les fais suivre à SYNPROXY.
# C'est à ce moment que synproxy répond le SYN-ACK à l'émeteur du SYN et créer une connexion à l'état ESTABLISHED dans conntrack, si et seulement si l'émetteur retourne un ACK valide.
# Note : Les paquets avec un tcp-cookie invalides sont dropés, mais pas ceux avec des flags non-standard, il faudra les filtrer par ailleurs. 
-A INPUT -i eth0 -p tcp -m multiport --dports 22,80,443 -m tcp -m state --state INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460

# 3. en input-filter, la règles SYNPROXY doit être suivi de celle-ci pour rejeter les paquets restant en état INVALID.
-A INPUT -i eth0 -p tcp -m multiport --dports 22,80,443 -m tcp -m state --state INVALID -j DROP
