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

### Règles anti-DDOS

Le principe d'un DDOS est de saturer le serveur de requêtes jusqu'a ce qu'il s'effondre par manque de ressources. La défense locale au serveur consiste à droper le plus efficacement possible toutes les demandes de connexions anormales. Il existe différent type de DDOS, certains se contente de spammer des SYN vers votre serveur (en espérant ouvrir plein de connexions en attente, et saturer votre machine de connexion en attente) et d'autre allant un peu plus loin dans le [3-way handshake TCP](https://fr.wikipedia.org/wiki/Three-way_handshake) (3WHS) toujours avec le même objectif. L'idée dans la tête de l'attaquant c'est de faire plein d'opérations peu coûteuses pour lui (établir des connexions TCP avec votre serveur et ne pas les suivre) et coûteuses pour votre machine (garder ouvertes tout un tas de connexions en attentes ou inactive)

#### Loose et invalid state

Un des premières règles consiste à désactiver le mode  « loose » (ça ne s'invente pas) de votre kernel. Ce dernier autorise par défaut un paquet ACK ouvrir une connexion sur votre serveur (sautant ainsi les deux premières étapes du 3WHS).

On a déjà fait ça plus haut en mettant l'option nf_conntrack_tcp_loose à 0 dans le kernel. Combiné ça avec une règle qui drop les connexions dans un état invalide et vous empêchez ces paquets ACK d'établir des connexions avec votre serveur.

```bash
*filter
-A INPUT -m state --state INVALID -j DROP
````
#### SynProxy

Synproxy est un mécanisme introduit dans la 1.4.1 d'iptables pour permettre de répondre efficacement aux attaques par SYN flooding (i.e. noyer le serveur sous des demandes de SYN qui ne seront pas suivi ACK). Le principe est de sortir les paquets SYN du connection-tracker d'iptables (conntrack) dont les opérations sont assez coûteuses en ressources et d'établir à la places les connexions au travers d'un proxy-TCP optimisé pour traiter spécifiquement ce type de demandes et ne transmettre à votre serveur que les connexions TCP correctement établies.

[![](https://cdn-js-head.geekeries.org/wp-content/uploads/2017/11/synproxy-concept.png)](https://people.netfilter.org/hawk/presentations/nfws2014/iptables-ddos-mitigation_RMLL.pdf)

On peut le mettre en place à l'aide des lignes suivantes :

```bash
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
```

Cette partie mérite qu'on s'y attarde un peu. La première règle se fait en PREROUTING-raw dès la réception du paquet, empêchant ainsi toute consommation inutile de mémoire. Notre paquet passera ensuite en PREROUTING-mangle, permettant de filtrer les paquets anormaux, et arrivera alors à la règle 2 ou SYN-PROXY fera son boulot créer des connexions ESTABLISHED seulement lorsque le client effectue un 3WHS valide. La dernière règle rejette enfin toutes les connexions restantes dans un état INVALID, appliquant au passage la protection contre les états invalides qu'on a vu juste avant.

### Maîtrise de charge

Bon on s'est protégé des DDOS simples à base de SYN et de ACK TCP, mais on ne fait rien pour gérer un surnombre de connexions normales qui atteignent l'état ESTABLISHED. Potentiellement toutes ces connexions sont légitimes, du coup soit on laisse tout passer, soit on essaye de limiter la casse.

Pour cela, une technique consiste à regrouper les IP sources par bloc de 256 (i.e par subnet source en /24) et de n'autoriser qu'un nombre maximum de demandes de connexions SYN par seconde pour chaque subnet. On peut faire ça avec le module hashlimit. Cela aura le mérite mettre un plafond de connexion par seconde vers votre serveur par groupe de 256 IP.

```bash
*raw
-A PREROUTING -i eth0 -p tcp -m tcp --syn -m multiport --dports 22,80,443 -m hashlimit --hashlimit-above 200/sec --hashlimit-burst 1000 --hashlimit-mode srcip --hashlimit-name syn --hashlimit-htable-size 2097152 --hashlimit-srcmask 24 -j DROP
```

On peut appliquer une règle similaire sur le nombre de connexions maximum autorisées en simultané par une seule IP source à l'aide du module connlimit.

```bash
*filter
-A INPUT -i eth0 -p tcp -m connlimit --connlimit-above 100 -j REJECT
```

Ce qui empêchera une seule IP de créer un nombre insensé de connexions avec votre serveur.

### Blacklisting portscanner

Une technique que l'on a pas abordée pour l'instant c'est le portscan, un petit [man nmap](http://lmgtfy.com/?q=man+nmap) vous en dira plus si vous ne savez pas ce que c'est. En gros, un attaquant cherche à découvrir quels sont les services ouverts sur votre serveur et va tenter d'établir une connexion TCP (plus ou moins valide) sur tous les ports courants, voire carrément les 65535 ports, et attendre la réponse du serveur pour détecter ceux ouvert.

Une première technique consiste à limiter le nombre de paquets typique d'un scan, Il y a [cet article](http://blog.sevagas.com/?Iptables-firewall-versus-nmap-and,31) qui explique bien comment on fait ça. Mais pour ma part, je ne vois pas l'intérêt de limiter ce qu'on peut droper directement... du coup la plupart de mes règles anti « bordel d'internet » plus haut avec le SYNPROXY force déjà l'attaquant à faire un 3WHS dans les règles pour voir ce qui se passe la ou c'est ouvert, et la policy DROP en INPUT jettera tout le reste...

Du coup on peut passer à une règle que je trouve plus rigolote, qui consiste à « piéger des ports » qui ne sont pas utilisés sur la machine, et blacklister pour un certains temps les machines qui essayer de s'y connecter.

On peut faire ça avec les règles suivantes.

```bash
*filter
-A INPUT -m recent --rcheck --seconds 86400 --name portscan --mask 255.255.255.255 --rsource -j DROP
-A INPUT -m recent --remove --name portscan --mask 255.255.255.255 --rsource
-A INPUT -p tcp -m multiport --dports 25,445,1433,3389 -m recent --set --name portscan --mask 255.255.255.255 --rsource -j DROP
```

Alors attention avec cette règle, un attaquant motivé qui s'en rendrait compte, pourrait forger des paquets TCP ([qui a dit Scapy ?](http://www.secdev.org/projects/scapy/)) à destination d'un de ces ports mais avec des IP sources fausses. Conséquence : votre serveur va se mettre à blacklister tout internet pour 24h si l'attaquant décide de parcourir la plage IPv4 complète... Du coup, c'est une règle qui fonctionne bien sur un petit serveur perso sans prétention mais je n'irai pas la mettre en production sur un frontal-web d'une grande boite... Et pensez à mettre en whitelist votre IP personnelle ou du boulot avec cette règle, ça vous évitera de vous faire jeter pour 24h le jour ou vous l'aurez oublié et que vous lancerez un scan de votre machine :

! -s <IPperso>,<IPboulots>[/NETMASK]

Notez aussi que vous pouvez voir quelles sont les IP blacklistées dans le fichier :

/proc/net/xt_recent/portscan

Enfin, il est bon de noter que la table du module « recent » est limitée a 100 entrées (par défaut). C'est (très) rapidement plein pour l'usage que je vous présente ici (et pour un serveur exposé sur Internet) ce qui limite son intérêt. Aussi je vous conseille d'augmenter la taille de cette table en créant un fichier « modprod.conf » (pour régler une option de ce module kernel) pour augmenter cette limite et que cela s'applique au démarage de la machine :

echo "options xt_recent ip_list_tot=2048" > /etc/modprobe.d/xt_recent.conf # Ajuster la valeur selon la capacité de votre serveur. Il faut un reboot pour qu'elle soit appliquée.

C'est bon moyen de faire une liste d'IP pourries sur lesquels tester un nmap...^^

### Et enfin, accepter les connexions sur des port.

Déjà vu plus haut, pour finir on autorise enfin des connexions entrantes :

```bash
*filter
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT
``` 
Bonus

Bon il me reste quelques règles bonus ou optionnelles à vous proposer, en liste à la Prévert :

On dégage le ping :

```bash
*mangle
-A PREROUTING -p icmp -j DROP
```

Bloquer la fragmentation TCP

```bash
*mangle
-A PREROUTING -f -j DROP
```
Notez pour finir que Fail2ban ajoute tout seul des règles dans votre firewall iptables, mais j'en ai déjà parlé dans [cet article](http://geekeries.org/2016/12/rapide-focus-sur-fail2ban/).

Conclusion
----------

Ça vous a paru long ? je n'ai fais qu'effleurer la surface de l'iceberg iptables, je vous invite à parcourir les 2477 lignes du [man iptables-extensions](http://lmgtfy.com/?q=man+iptables-extensions) pour vous rendre compte des possibilités offerte par iptables. Dans les choses sympa que je vous invite à creuser par vous même :

1.  La target LOG qui vous permettra de journaliser les connexions qui vous intéresses (méfiez-vous ça peut cracher un paquet de lignes). Voir [cet article](https://geekeries.org/2018/04/logs-iptables/) sur le sujet des logs avec iptables.
2.  Le module CPU pour mettre en oeuvre une répartition de charge de l'établissement des connexions TCP sur les différents CPU de votre serveur.
3.  Le module time qui permet par exemple de fermer un service automatiquement le weekend ou à certaines heures.

Voilà, j'ai eu du mal à trouver un ensemble de règles « à peu près correctes » dehors (par contre j'ai trouvé pas mal de n'importe quoi...^^). Donc j'espère que ça en aidera certains, et posez vos questions dans les commentaires !
