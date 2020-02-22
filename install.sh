#!/bin/bash

# Tested on Ubuntu 18.04
# wget -O - https://raw.githubusercontent.com/Dyakovvn/lazyinstall/master/install.sh | bash
# install docker + docker-compose, get some system tweaks

apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce mc ifstat atop htop mtr git tcpdump rsync ca-certificates vnstat dnsutils smartmontools libwww-perl fail2ban strace
curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# some basic sysctl tweaks
echo "kernel.shmmax = 1073741824" >> /etc/sysctl.d/99-tweaks.conf
echo "kernel.shmmax = 1073741824" >> /etc/sysctl.d/99-tweaks.conf
echo "kernel.pid_max = 2097152" >> /etc/sysctl.d/99-tweaks.conf
echo "kernel.sched_migration_cost_ns = 5000000" >> /etc/sysctl.d/99-tweaks.conf
echo "fs.file-max = 2097152" > /etc/sysctl.d/99-tweaks.conf
echo "net.core.somaxconn = 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.netdev_max_backlog = 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.rmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.rmem_default = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.wmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.wmem_default = 65536" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.optmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.ip_local_port_range = 2000 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_max_syn_backlog = 40000" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_rmem = 4096 25165824 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_wmem = 4096 65536 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_fin_timeout = 25" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_keepalive_time=60" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_keepalive_probes=3" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_keepalive_intvl=15" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_sack = 0" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_mtu_probing = 0" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_rfc1337 = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.netfilter.nf_conntrack_max = 1548576" >> /etc/sysctl.d/99-tweaks.conf
echo "net.nf_conntrack_max = 1548576" >> /etc/sysctl.d/99-tweaks.conf
echo "vm.swappiness = 5" >> /etc/sysctl.d/99-tweaks.conf
echo "vm.overcommit_memory = 1" >> /etc/sysctl.d/99-tweaks.conf
sysctl -p /etc/sysctl.d/99-tweaks.conf

# systemd tweaks
sed -i 's/#DefaultLimitNOFILE=/DefaultLimitNOFILE=2097152/g' /etc/systemd/system.conf
sed -i "s/#DefaultLimitMEMLOCK=/DefaultLimitMEMLOCK=infinity/g" /etc/systemd/system.conf
sed -i "s/#DefaultLimitAS=/DefaultLimitAS=infinity/g" /etc/systemd/system.conf
sed -i "s/#DefaultLimitRSS=/DefaultLimitRSS=infinity/g" /etc/systemd/system.conf
sed -i "s/#DefaultLimitCORE=/DefaultLimitCORE=infinity/g" /etc/systemd/system.conf
systemctl daemon-reload
