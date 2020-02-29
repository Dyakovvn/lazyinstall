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
    echo "* Flushing iptables"
    iptables -F -t nat
    iptables -F
    echo "* Reloading iptables"
    /sbin/iptables-restore < /root/scripts/rules.v4
    /sbin/ip6tables-restore < /root/scripts/rules.v6
    echo "* Restarting docker"
    service docker restart
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
        ipt_ipset
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