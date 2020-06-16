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

