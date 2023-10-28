#!/bin/bash
# Author: Rickard Andersson 
# Add a worker node for a RKE2 cluster
# Add the clustertoken, hostname, cni type (calico/canal),RKE2-version and the server url/ip to the masternode of the cluster
ROOT_UID=0
os_release="$( ( . /etc/os-release && printf '%s\n' "$NAME" ) | awk '{ print $1 }' )"
cni_type=
token=
vm_name=
k8s_server=
rke2_version=v1.25.13+rke2r1

echo "Let's check if you're root!"
if [ "$UID" -eq "$ROOT_UID" ]
  then echo "You'are root and the installation precedes!"
else
    echo "Sorry, You're not root.."
  echo "Terminating the script.."
  exit 1
fi

swapoff -a
timedatectl set-timezone Europe/Stockholm
echo br_netfilter > /etc/modules-load.d/br_netfilter.conf
systemctl restart systemd-modules-load.service
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
modprobe br_netfilter
sysctl -p
touch /etc/sysctl.d/sysctl.conf
touch /etc/sysctl.d/90-rke2.conf
cat << EOF > /etc/sysctl.d/sysctl.conf
net.bridge.bridge-nf-call-iptables=1
EOF
sysctl -p /etc/sysctl.d/sysctl.conf
cat << EOF > /etc/sysctl.d/90-rke2.conf
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF
sysctl -p /etc/sysctl.d/90-rke2.conf

if [ "$os_release" == "openSUSE" ]
    then
  echo "Updating repo and packages and installing curl,wget and apparmor."
    zypper --quiet ref
    zypper --quiet up
    zypper --quiet install apparmor-parser wget curl -y
  systemctl stop firewalld
  systemctl disable firewalld

elif [ "$os_release" == "Ubuntu" ]
    then
  echo "Updating repo and packages and installing curl,wget and apparmor."
    apt update
    apt upgrade -y
    apt install curl wget apparmor -y
    sed -e '/swap/ s/^#*/#/g' -i /etc/fstab
else
    echo "You're running neither Ubuntu or OpenSuse!"
    exit 1
fi
systemctl enable apparmor --now
mkdir -p /etc/rancher/rke2/
curl -sfL https://get.rke2.io --output install.sh
chmod +x install.sh
INSTALL_RKE2_CHANNEL=$rke2_version ./install.sh
cat << EOF > /etc/rancher/rke2/config.yaml
write-kubeconfig-mode: '0600'
token: $token
server: $k8s_server
tls-san:
- vip-address
- $vm_name
cni:
- $cni_type
EOF
systemctl enable rke2-agent --now
exit 0