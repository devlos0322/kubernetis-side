#!/usr/bin/env bash

# $1: 쿠버네티스 버전, $2: main 여부

# install packages
yum install epel-release -y
yum install vim-enhanced -y
yum install git -y

# install docker
yum install docker -y && systemctl enable --now docker

#install kubernetes cluster. 마스터 및 워커노드에 필요한 kubectl, kubelet kubeadm 설치
yum install kubectl-$1 kubelet-$1 kubeadm-$1 -y
systemctl enable --now kubelet

# git clone _Book_k8sInfra.gi. Main에만 실습환경에 필요한 리소스를 받기 위해 분기
if [ $2 = 'Main']; then
    git clone https://github.com/sysnet4admin/_Book_k8sInfra.git
    mv /home/vagrant/_Book_k8sInfra $HOME
    find $HOME/_Book_k8sInfra/ -regex ".*\.\(sh\)" -exec chmod 700 {} \;
fi
