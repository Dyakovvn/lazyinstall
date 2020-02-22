#!/bin/bash

apt update && apt upgrade -y
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce mc ifstat atop htop mtr git tcpdump rsync ca-certificates vnstat dnsutils smartmontools libwww-perl
curl -L "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# some basic tweaks
echo "fs.file-max = 2097152" > /etc/sysctl.d/99-tweaks.conf
echo "net.core.somaxconn = 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "vm.overcommit_memory = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.netdev_max_backlog = 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.ip_local_port_range = 2000 65535" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_rmem = 4096 25165824 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.rmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.rmem_default = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.ipv4.tcp_wmem = 4096 65536 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.wmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.wmem_default = 65536" >> /etc/sysctl.d/99-tweaks.conf
echo "net.core.optmem_max = 25165824" >> /etc/sysctl.d/99-tweaks.conf
echo "kernel.shmmax = 1073741824" >> /etc/sysctl.d/99-tweaks.conf
echo "net.netfilter.nf_conntrack_max = 1548576" >> /etc/sysctl.d/99-tweaks.conf
echo "net.nf_conntrack_max = 1548576" >> /etc/sysctl.d/99-tweaks.conf
sysctl -p /etc/sysctl.d/99-tweaks.conf
