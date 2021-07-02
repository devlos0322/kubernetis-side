#!/user/bin/env bash

# vim configuration
echo 'alias vi=vim' >> /etc/profile # vi명령어 입력시 vim을 호출 

# swapoff -a to disable swapping
swapoff -a
# sed to comment toe swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# kubernetis repo
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernets.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgckeck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

#RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
# 브리지 네트워크를 통과하는 IPv4, IPv6의 패킷을 iptables가 관리하게 설정. Pod의 통신을 iptable로 제어
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br-netfilter #br-netfilter 커널 모듈을 사용해 브리지로 네트워크 구성. 이때 IP 마스커레이드를 사용해 내부 네트워크와 외부 네트워크를 분리. 29~32번째 줄 활성화

# local small dns & batant cannot parse and delivery shell code.
echo "192.168.1.10 m-k8s" >> /etc/hosts
for ((i=1; i<=$1; i++ )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done # 쿠버네티스 내부에서 노드간 통신을 이름으로 할 수 있도록 각 노드의 호스트 이름과 IP를 /etc/hosts에 설정

# config DNS. 외부와 통신할 수 잇게 DNS서버 지정
cat <<EOF> /etc/resolve.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF