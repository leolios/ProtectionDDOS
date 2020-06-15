#!/bin/bash
#  _________                  __________               _____ 
# /   _____/ ______________  _\______   \ ____________/ ____\
# \_____  \_/ __ \_  __ \  \/ /|     ___// __ \_  __ \   __\ 
# /        \  ___/|  | \/\   / |    |   \  ___/|  | \/|  |   
#/_______  /\___  >__|    \_/  |____|    \___  >__|   |__|   
#        \/     \/                           \/              
#
# 			By Lucas D.
#			DDOS Protection ( Layer 4 & Layer 7 )
#
######## OS Type ###############
APT=/usr/lib/apt/
YUM=/usr/lib/yum-plugins/
curl=/usr/bin/curl
iptables=/sbin/iptables
#color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
REDBG=$(tput setab 1)
GREENBG=$(tput setab 2)
YELLOWBG=$(tput setab 3)
BLUEBG=$(tput setab 4)
MAGENTABG=$(tput setab 5)
CYANBG=$(tput setab 6)
WHITEBG=$(tput setab 7)

#Supported systems:
supported="RHEL & Debian"

cat << "EOF"

  _________                  __________               _____ 
 /   _____/ ______________  _\______   \ ____________/ ____\
 \_____  \_/ __ \_  __ \  \/ /|     ___// __ \_  __ \   __\ 
 /        \  ___/|  | \/\   / |    |   \  ___/|  | \/|  |   
/_______  /\___  >__|    \_/  |____|    \___  >__|   |__|   
        \/     \/                           \/              
        
EOF
# Root Force
 if [ "$(id -u)" != "0" ]; then
         printf "${RED}⛔️ Attention droit root obligatoire ⛔️\\n" 1>&2
         printf "\\n"
         exit 1
 fi
    printf "${RED}⛔️ Protection pour VPS / Dédié / Container ⛔️\\n"
    printf "${RED}⛔️ Réduction des attaques DDoS en Layer 4 et Layer 7⛔️\\n"
    printf "\\n"
    printf "${WHITE}Supporte:${MAGENTA} $supported \\n"
    printf "${CYAN}\\n"
    echo "-------------------------------------"
    printf "Pour continuer appuyez sur entrer...\\n"
    echo "-------------------------------------"
    read -p ""
    printf "Exécution du script en cours...\\n"
    printf "\\n"
#############################################################################

# Install iptables and update all the packets

printf "\\n"
apt update -y
apt install python3 python3-pip -y
mkdir -p $Folder > /dev/null 2>&1
if [ -f "$curl" ]; then
       curl https://raw.githubusercontent.com/Ghost-devlopper/IPbanner/master/Banip.py --output /usr/bin/ipban
    else 
apt install curl -y
        curl https://raw.githubusercontent.com/Ghost-devlopper/IPbanner/master/Banip.py --output /usr/bin/ipban
fi
if [ -f "$iptables" ]; then
    echo""
    else 
$Installer install iptables -y
fi
chmod +x /usr/bin/ipban 2>&1

echo
    printf "${BLUE} Avez-vous un serveur SSH ❓ [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
    printf "${RED} Souhaitez-vous bloquer le SSH Brute-Force ❓ [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then
/sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
        /sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
fi
echo        
        printf "${CYAN} Parfait les règles sont activent !"
        /sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
        /sbin/iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
fi
echo
    printf "${YELLOW} Souhaitez-vous bloquer le Port Scan ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
        printf "${CYAN} D'accord, les règles sont désormais actives !"
 	/sbin/iptables -A INPUT   -m recent --name portscan --rcheck --seconds 86400 -j DROP
        /sbin/iptables -A FORWARD -m recent --name portscan --rcheck --seconds 86400 -j DROP
        /sbin/iptables -A INPUT   -m recent --name portscan --remove
        /sbin/iptables -A FORWARD -m recent --name portscan --remove
fi
echo
echo
    printf "${YELLOW} Voulez vous bloquer les packets invalides ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} D'accord, les règles sont désormais actives !"
iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
fi
echo
echo
    printf "${YELLOW} Voulez vous bloquer les packets non SYN ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} Youpi ! Les packets SYN sont désormais bloqués !"
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
fi
echo
echo
    printf "${YELLOW} Voulez vous bloquer les packets avec faux drapeaux TCP ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} Génial ! Les packets TCP sont désormais bloqués !"
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
fi
echo
echo
    printf "${YELLOW} Voulez vous bloquer les packets depuis les subnets privés ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} C'est Fait !"
iptables -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP 
iptables -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP 
iptables -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP 
iptables -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP 
iptables -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP 
iptables -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP 
iptables -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP 
iptables -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP 
iptables -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP
fi
echo
echo
    printf "${YELLOW} Voulez vous bloquer les packets ICMP ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} La règle est désormais active !"
iptables -t mangle -A PREROUTING -p icmp -j DROP
iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 -j REJECT --reject-with tcp-reset
fi
echo
echo
    printf "${YELLOW} Voulez vous limiter les requêtes TCP sur le port 80 ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} C'est désormais activé !"
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 15 --connlimit-mask 10 -j REJECT --reject-with tcp-reset
fi
echo
echo
    printf "${YELLOW} Voulez vous limiter les requêtes TCP sur le port 443 ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} C'est désormais activé !"
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 15 --connlimit-mask 10 -j REJECT --reject-with tcp-reset
fi
echo
echo
    printf "${YELLOW} Voulez vous limiter les connexions simultanées sur votre serveur? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
printf "${CYAN} C'est désormais activé !"
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT 
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
fi
echo
echo
    printf "${YELLOW} Souhaitez-vous bloquer les fragments dans toutes les chaînes ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
    printf "${CYAN} Parfait la règle est active ! \\n"
iptables -t mangle -A PREROUTING -f -j DROP
fi
echo
    printf "${YELLOW} Voulez vous activer le système de mitigation SYNPROXY (Bêta) [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
    printf "${CYAN} Parfait le SYNPROXY est actif ! \\n"
iptables -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack 
iptables -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460 
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
fi
echo
    printf "${YELLOW} Voulez vous que les règles s'activent automatiquement au démarrage ? [o/N]\\n"
    read reponse
if [[ "$reponse" == "o" ]]
then 
   iptables-save && iptables-save &gt; /etc/iptables/rules.v4 && iptables-save &gt; /etc/iptables/rules.v6
printf "${CYAN} Règles actives ! \\n"
fi
printf "${CYAN} L'installation du système anti-DDOS est terminé ! \\n"
printf "${CYAN} La commande ipban est désormais disponible\\n"
printf "${WHITE}\\n"
