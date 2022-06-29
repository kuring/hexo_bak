title: docker client常用操作
date: 2022-05-31 14:28:37
tags:
author:
---
- 打包操作：`docker save k8s.gcr.io/kubernetes-dashboard-amd64:v1.8.3  | gzip > tmp.gzip`
- 镜像导入操作：`gunzip -c mycontainer.tgz | docker load`: 导入打好的包
