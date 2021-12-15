---
title: ecs主机上快速创建测试k8s集群
date: 2021-12-15 21:32:00
tags:
---

经常有快速创建一个测试k8s集群的场景，为了能够快速完成，整理了如下的命令，即可在主机上快速启动一个k8s集群。部分命令需要外网访问，推荐直接使用海外的主机。

# 安装docker

```shell
yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl enable docker && systemctl start docker
```

# 安装kubectl kind helm

```
# 安装kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/bin/
kubectl completion bash >/etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

# 安装helm
wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
tar zvxf helm-v3.7.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/bin/
rm -rf linux-amd64

# 安装kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/bin/
```

# 创建集群

```
cat > kind.conf <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
EOF
kind create cluster --config kind.conf
```
