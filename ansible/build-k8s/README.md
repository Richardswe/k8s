Build a Kubernetes cluster using RKE2 via Ansible
=========
```
               ,        ,  _______________________________
   ,-----------|'------'|  |                             |
  /.           '-'    |-'  |_____________________________|
 |/|             |    |
   |   .________.'----'    _______________________________
   |  ||        |  ||      |                             |
   \__|'        \__|'      |_____________________________|

|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|
|________________________________________________________|

|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|
|________________________________________________________|
```

Ansible RKE2 (RKE Government) Playbook
---------
[![LINT](https://github.com/rancherfederal/rke2-ansible/actions/workflows/ci.yml/badge.svg)](https://github.com/rancherfederal/rke2-ansible/actions/workflows/ci.yml)

RKE2, also known as RKE Government, is Rancher's next-generation Kubernetes distribution. This Ansible  playbook installs RKE2 for both the control plane and workers.

See the [docs](https://docs.rke2.io/) more information about [RKE Government](https://docs.rke2.io/).


Platforms
---------
The RKE2 Ansible playbook supports all [RKE2 Supported Operating Systems](https://docs.rke2.io/install/requirements/#operating-systems)

Supported Operating Systems:
```yaml
SLES:
  - 15 SP2 (amd64)
  - 15 SP3 (amd64)
  - 15 SP3 JEOS (amd64)
  - 15 SP4 JEOS (amd64)
CentOS:
  - 7.8 (amd64)
  - 8.2 (amd64)
Red Hat:
  - 7.8 (amd64)
  - 8.2 (amd64)
Ubuntu:
  - bionic/18.04 (amd64)
  - focal/20.04 (amd64)
```

Added custom features 
---------------------

2022 august to 10th of november
It has been added to install apparmor for Suse distros and to enable and start the service
It has also been added that the name of the node is added in the server and agent config file


System requirements
-------------------

Deployment environment must have Ansible 2.9.0+

Server and agent nodes must have passwordless SSH access

Usage
-----

This playbook requires ansible.utils to run properly. Please see https://docs.ansible.com/ansible/latest/galaxy/user_guide.html#installing-a-collection-from-galaxy for more information about how to install this.

```
ansible-galaxy collection install -r requirements.yml
```

Create a new directory based on the `sample` directory within the `inventory` directory:

```bash
cp -R inventory/sample inventory/my-cluster
```
NOTE you can edit the following files in build-k8s with the names vm-hosts,vm-inventory,resolv-config and rke2-vars

Edit the hosts file in roles/dist-files/files/hosts
to match your enviroment example;
10.2.2.10   k8s-vm01
10.2.2.11   k8s-vm02

Edit the roles/dist-files/resolv.conf and add the dns servers you prefer. 

Edit the roles/rke2_common/vars/main.yml 
add the rke2 version 

Last, edit `inventory/my-cluster/hosts.ini` to match the system information gathered above. For example:

```bash
[rke2_servers]
192.16.35.12

[rke2_agents]
192.16.35.[10:11]

[rke2_cluster:children]
rke2_servers
rke2_agents
```

If needed, you can also edit `inventory/my-cluster/group_vars/rke2_agents.yml` and `inventory/my-cluster/group_vars/rke2_servers.yml` to match your environment.

Start provisioning of the cluster using the following command:

```bash
ansible-playbook site.yml -i inventory/my-cluster/hosts.ini -u vagrant 
```

Tarball Install/Air-Gap Install
-------------------------------
Added the needed files to the [tarball_install](tarball_install]/) directory. 
Both rke2.linux-amd64.tar.gz and rke2-images.linux-amd64.tar.gz and the sha256sum-amd64.txt.


Further info can be found [here](tarball_install/README.md)


Kubeconfig
----------

To get access to your **Kubernetes** cluster just

```bash
ssh ec2-user@kubernetes_api_server_host "sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes"
```

Label nodes
-----------
```
declare -a kube_nodes=$(kubectl get nodes --show-labels | grep -v master | awk '(NR>1)' | awk '{ print $1 }')
for nodes in ${kube_nodes[@]}; do
  kubectl label nodes "$nodes" node-role.kubernetes.io/worker=worker
done
```

Important
----------
When you're placing your rke2-config lines in the rke2-server or rke2-agent yaml file
you have to be sure that they don't intervene with variables set by the playbook, it may cause so the agent node won't join the cluster.

Available configurations
------------------------
Set the RKE2 version in rke2_common/vars/main.yaml
Set the hostnames and node ip's in roles/dist-files/files/hosts
Set nameservers in roles/dist-files/files/resolv.conf
Variables should be set in `inventory/cluster/group_vars/rke2_agents.yml` and `inventory/cluster/group_vars/rke2_servers.yml`. See sample variables in `inventory/sample/group_vars` for reference.


Uninstall RKE2
---------------
    Note: Uninstalling RKE2 deletes the cluster data and all of the scripts.
The offical documentation for fully uninstalling the RKE2 cluster can be found in the [RKE2 Documentation](https://docs.rke2.io/install/uninstall/).

If you used this module to created the cluster and RKE2 was installed via yum, then you can attempt to run this command to remove all cluster data and all RKE2 scripts.

Replace `ec2-user` with your ansible user.
```bash
ansible -i 18.217.113.10, all -u ec2-user -a "/usr/bin/rke2-uninstall.sh"
```

If the tarball method was used then you can attempt to use the following command:
```bash
ansible -i 18.217.113.10, all -u ec2-user -a "/usr/local/bin/rke2-uninstall.sh"
```
On rare occasions you may have to run the uninstall commands a second time.


Author Information
------------------

[Dave Vigil](https://github.com/dgvigil)

[Brandon Gulla](https://github.com/bgulla)

[Rancher Federal](https://rancherfederal.com/)

[Mike D'Amato](https://github.com/mdamato)