# Run this script to install a kubeadm worker node. And run the scripts written in the end. 
# Remeber to specify version on row 3-4 and row 58 if you want to modify the hostsfile. And last change the containerd version,
# row 46.
KUBERNETES_VERSION="1.21.14-00"
KUBERNETES_VER="1.21.14"
NODENAME=$(hostname -s)

apt update

apt -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install vim git curl wget -y
apt install -y kubelet="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"

swapoff -a
sleep 5

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

# Install container runtime

tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

sysctl --system
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sleep 5
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update

wget http://security.ubuntu.com/ubuntu/pool/universe/c/containerd/containerd_1.5.5-0ubuntu3~18.04.2_amd64.deb
apt-get install -y --allow-change-held-packages ./containerd_1.5.5-0ubuntu3~18.04.2_amd64.deb

mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd --now
lsmod | grep br_netfilter
systemctl enable kubelet --now
kubeadm config images pull
kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock

cat << EOF >> /etc/hosts
172.22.100.18 k8s-vm01
172.22.100.19 k8s-vm02
172.22.100.20 k8s-vm03
172.22.100.21 k8s-vm04
EOF

# Join a worker
# On the master node run the command;
# kubeadm token create --print-join-command
# Run the output on the worker node, It should be similar to this
# kubeadm join 10.14.10.39:6443 --token 55ekme.0ahjmz09920bqsyt --discovery-token --ca-cert-hash
#
#
# Label only nodes that don't have the label "master"
# Label them as "worker"
#declare -a kube_nodes=$(kubectl get nodes --show-labels | grep -v master | awk '(NR>1)' | awk '{ print $1 }')
#for nodes in ${kube_nodes[@]}; do
#kubectl label nodes "$nodes" node-role.kubernetes.io/worker=worker
#done