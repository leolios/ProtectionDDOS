# DDOSProtection

Commandes à utilisé une fois le sysctl.conf configuré

Plus un dernier tweak :

echo 'options nf_conntrack hashsize=500000' > /etc/modprobe.d/nf_conntrack.conf # (Calculate your own values ! depending on your hardware)
mais qui nécessite un reboot pour être appliquée, donc on le place directement :

echo 500000 > /sys/module/nf_conntrack/parameters/hashsize
Vous pouvez alors appliquer ces modifications ainsi :

sysctl -p

### Configuration avancée du firewall iptables

> Note : A partir de maintenant je ne donne plus les règles à appliquer dans le format « ligne de commande » mais dans le format fichier de sauvegarde iptables issue du iptables-save. Pour appliquer ces nouvelles règles il faut alors modifier le fichier/etc/iptables/rules.v4, et exécuter commande suivante :
>
> iptables-restore < /etc/iptables/rules.v4
>
> Ce mode de fonctionnement permet d'appliquer plusieurs règles « en même temps » et en travaillant sur un fichier. Ce qui est plus pratique que d'appliquer des modifs en live sans se rappeler de la ligne précédente...

### Règles anti « bordel d'internet »

Vous seriez surpris du nombre de tentatives de connexions TCP *bizarres* qu'on trouve sur Internet : [Xmas Scan par nmap](https://nmap.org/man/fr/man-port-scanning-techniques.html) n'est un exemple avec toutes les flags TCP à 1. Du coup, voici un jeu de règles permettant de rejeter sans trop se poser de questions les connexions TCP avec des combinaisons de flag impossibles ou improbables :

```bash
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
```

On peut également établir d'autres règles de filtrage triviales basées sur les IP sources en dropant tout ce qui arrive d'un réseau privé/réservé. C'est du spoofing d'IP source, c'est très peu probable pour un serveur avec uniquement une IP publique sur Internet.

```bash
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
```

Et voilà, après j'ai quelques règles bonus dans le même genre que je vous met à la fin.
