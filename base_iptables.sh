#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
export PATH=$PATH

ipset -q -N access iphash
ipset -q -N day_whitelist iphash

function valid_ip()
{
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function ipt_ipset()
{
    ## Ipset filling
    for ip in `curl -s https://sec.advmt.org/advmsys.php?get=iplist`
    do
	if valid_ip $ip
	then
    	    ipset -q -A access $ip
	fi
    done;
    echo "IPSET reloaded"
}

function ipt_stop()
{
    iptables --flush
    iptables --delete-chain
    iptables --table nat --flush
    iptables --table nat --delete-chain
    iptables --table filter --flush
    iptables --table filter --delete-chain
    iptables -t filter -P INPUT ACCEPT
    iptables -t filter -P OUTPUT ACCEPT
    iptables -t filter -P FORWARD ACCEPT
    echo "Firewall stopped"
}

function ipt_start()
{
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

    # web http + https
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

    # Allow all for IPs from IPSET table
    iptables -t filter -A INPUT -m set --match-set access src -m comment --comment "Secure access list" -j ACCEPT
    iptables -t filter -A INPUT -m set --match-set day_whitelist src -m comment --comment "DAY Access access list" -j ACCEPT
}

case $1 in
    stop)
        ipt_stop
    ;;

    restart)
	$0 stop
	$0 start
    ;;

    start)
        ipt_start
        ipt_reload
        ipset save > /etc/default/ipset
        iptables-save > /etc/default/iptables
        echo "Firewall started"
    ;;

    ipset|reload)
        ipt_ipset
    ;;

    *)
	echo "Use only start / stop / restart / reload"
	echo "Reloading ipset rules"
	$0 ipset
    ;;

esac
exit 0