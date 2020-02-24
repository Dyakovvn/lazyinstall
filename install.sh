#!/bin/bash

# Tested on Ubuntu 18.04
# wget -O - https://raw.githubusercontent.com/Dyakovvn/lazyinstall/master/install.sh | bash
# install docker + docker-compose, get some system tweaks


apt -qq update && apt -qq upgrade -y
apt -qq install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt -qq update
echo "Install packages"
apt -qq install -y \
    zip \
    curl \
    docker-ce \
    mc \
    ifstat \
    atop \
    htop \
    mtr \
    git \
    tcpdump \
    rsync \
    ca-certificates \
    vnstat \
    dnsutils \
    smartmontools \
    libwww-perl \
    fail2ban \
    strace \
    sysfsutils \
    ntpdate \
    lsof \
    net-tools \
    telnet \
    traceroute \
    vim \
    jq \
    tmux \
    screen \
    logrotate \
    iotop \
    bash-completion \
    bc \
    sshpass \
    cpufrequtils

echo "Install docker-compose.."
curl -sL "https://github.com/docker/compose/releases/download/1.25.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "CPU Governor performance"
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
systemctl disable ondemand

echo "Some sysctl tweaks"
>/etc/sysctl.d/99-tweaks.conf << EOF
kernel.shmmax = 1073741824
kernel.shmmax = 1073741824
kernel.pid_max = 2097152
kernel.sched_migration_cost_ns = 5000000
fs.file-max = 2097152
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.core.rmem_max = 25165824
net.core.rmem_default = 25165824
net.core.wmem_max = 25165824
net.core.wmem_default = 65536
net.core.optmem_max = 25165824
net.ipv4.ip_local_port_range = 2000 65535
net.ipv4.tcp_syncookies = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_syn_backlog = 40000
net.ipv4.tcp_rmem = 4096 25165824 25165824
net.ipv4.tcp_wmem = 4096 65536 25165824
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_sack = 0
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_orphan_retries = 1
net.ipv4.netfilter.ip_conntrack_max = 1548576
net.netfilter.nf_conntrack_max = 1548576
net.nf_conntrack_max = 1548576
vm.swappiness = 1
vm.overcommit_memory = 1
EOF

sysctl -p /etc/sysctl.d/99-tweaks.conf

echo "Some systemd tweaks"
>/etc/systemd/system.conf << EOF
[Manager]
DefaultLimitNOFILE=2097152
DefaultLimitMEMLOCK=infinity
DefaultLimitAS=infinity
DefaultLimitRSS=infinity
DefaultLimitCORE=infinity
DefaultLimitNPROC=320000
EOF

>/etc/systemd/user.conf << EOF
[Manager]
DefaultLimitNOFILE=2097152
DefaultLimitMEMLOCK=infinity
DefaultLimitAS=infinity
DefaultLimitRSS=infinity
DefaultLimitCORE=infinity
DefaultLimitNPROC=320000
EOF

echo "pam tweaks"
>/etc/security/limits.conf << EOF
# /etc/security/limits.conf
* - memlock unlimited
* - nofile 2097152
* - nproc 32768
* - as unlimited
* - stack unlimited
root - memlock unlimited
root - nofile 2097152
root - nproc 32768
root - as unlimited
root - stack unlimited
# End of file

EOF

echo "activate pam limits"
LIMITS_SET=$(grep 'session required pam_limits' /etc/security/limits.conf)
if [ "${LIMITS_SET}" ]
 then
    echo "session required pam_limits already set to /etc/security/limits.conf"
 else
    echo "session required pam_limits.so" >> "/etc/pam.d/common-session"
fi


# Отключаем iptables в докере и рулим iptables`ом сами. Ибо это самый безопасный и контролируемый способ. В большинстве установок
echo "Disable docker autoconfiguration iptables."
IPTABLESDOCKER_SET=$(grep 'iptables=false' /lib/systemd/system/docker.service)
if [ "${IPTABLESDOCKER_SET}" ]
 then
    echo "Iptables alerady disabled in docker"
 else
    sed -i 's/containerd.sock/containerd.sock --iptables=false/g' /lib/systemd/system/docker.service
fi
systemctl daemon-reload


echo "Activate iptables after reboot"
IPTABLES_SET=$(grep 'iptables' /etc/crontab)
if [ "${IPTABLES_SET}" ]
 then
    echo "Iptables alerady set in crontab"
 else
    echo -ne "
@reboot	root iptables-restore < /etc/default/iptables
" >> "/etc/crontab"
fi

echo "SSH config. Disable password auth and dns resolve"
>/etc/ssh/sshd_config << EOF
Port 22
Protocol 2
PermitUserEnvironment yes
PermitRootLogin without-password
AllowUsers root update backuppc secure
X11Forwarding no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
RSAAuthentication yes
GSSAPIAuthentication no
ChallengeResponseAuthentication no
UseDNS no
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM yes
MaxAuthTries 5
PrintMotd no
AcceptEnv LANG LC_*
Subsystem	sftp	/usr/lib/openssh/sftp-server
EOF
service ssh restart

echo "Install NtpDate sync"
apt remove ntp -y
echo "0 * * * * root /usr/sbin/ntpdate 1.ru.pool.ntp.org 1>/dev/null 2>&1" > /etc/cron.d/ntpdate

echo "Create /root/scripts dir with iptables bash file"
mkdir -p /root/scripts
wget -O /root/scripts/iptables.sh https://raw.githubusercontent.com/Dyakovvn/lazyinstall/master/base_iptables.sh
chmod +x /root/scripts/iptables.sh

read -p "Execute Iptables now? Y/n" -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Install Iptables skipped"
else
    /bin/bash /root/scripts/iptables.sh
fi

echo "done. Reboot system now"
