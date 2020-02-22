#!/bin/sh

######################
# Default rules DROP #
######################
iptables -F
iptables -X

iptables -t raw -F
iptables -t raw -X

iptables -t nat -F
iptables -t nat -X

iptables -t mangle -F
iptables -t mangle -X

iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

#iptables -P INPUT DROP
#iptables -P OUTPUT ACCEPT
#iptables -P FORWARD DROP

iptables -F
iptables -F INPUT
iptables -F OUTPUT
iptables -F FORWARD
iptables -X

###################
# Public services #
###################

# ESTABLISHED
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i docker0 -j ACCEPT

# loopback
iptables -A INPUT -p all -i lo -j ACCEPT

# ICMP
iptables -A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type 12 -j ACCEPT

# ssh
iptables -A INPUT -p tcp -m multiport --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dport 443 -j ACCEPT

###############################################
# White lists ip-address (servers and office) #
###############################################

# Hetzner cloud network
iptables -A INPUT -p all -s 10.0.0.0/16 -m comment --comment "private cloud" -j ACCEPT

#iptables -A INPUT -p all -j LOG --log-prefix "IPT_DROPED: "

##### DOCKER
iptables -A FORWARD -o docker0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i docker0 ! -o docker0 -j ACCEPT
iptables -A FORWARD -i docker0 -o docker0 -j ACCEPT

iptables -A POSTROUTING -t nat -o eth0 -j MASQUERADE

iptables-save > /etc/default/iptables
echo "Firewall started"
