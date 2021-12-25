---
title: ecs的Linux主机上快速创建测试k8s集群
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
yum install vim git -y
```

# 安装kubectl kind helm

```
# 安装kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/bin/
yum install -y bash-completion
echo 'source <(kubectl completion bash)' >>~/.bash_profile
echo 'alias k=kubectl' >>~/.bash_profile
echo 'complete -F __start_kubectl k' >>~/.bash_profile
source ~/.bash_profile

# 安装helm
wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
tar zvxf helm-v3.7.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/bin/
rm -rf linux-amd64

# 安装kubectx kubens
git clone https://github.com/ahmetb/kubectx /tmp/kubectx
cp /tmp/kubectx/kubens /usr/bin/kns
cp /tmp/kubectx/kubectx /usr/bin/kctx
wget https://github.com/junegunn/fzf/releases/download/0.29.0/fzf-0.29.0-linux_amd64.tar.gz
tar zvxf fzf-0.29.0-llinux_amd64.tar.gz
mv fzf /usr/local/bin/

# 安装kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/bin/
```

# 创建集群

其中将apiServerAddress指定为了本机，即创建出来的k8s集群仅允许本集群内访问。如果要是需要多个k8s集群之间的互访场景，由于kind拉起的k8s运行在docker容器中，而docker容器使用的是容器网络，此时如果设置apiserver地址为127.0.0.1，那么集群之间就没法直接通讯了，此时需要指定一个可以在docker容器中访问的宿主机ip地址。

```
cat > kind.conf <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: 6443
EOF
kind create cluster --config kind.conf
```

# 其他周边工具

```
# 安装kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv /root/kustomize /usr/bin/

# 安装golang
mkdir /opt/gopath
mkdir /opt/go
echo 'export GOROOT=/opt/go' >> ./bash_profile
echo 'export GOPATH=/opt/gopath' >> ./bash_profile
echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ./bash_profile

# 安装controller-gen，会将controller-gen命令安装到GOPATH/bin目录下
go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest
```
