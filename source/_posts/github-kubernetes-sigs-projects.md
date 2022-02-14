title: Github Kubernetes SIGs组织下的项目（持续更新）
date: 2022-02-14 23:21:37
tags:
author:
---
# cluster-proportional-autoscaler

项目地址：https://github.com/kubernetes-sigs/cluster-proportional-autoscaler

k8s默认提供了hpa机制，可以根据pod的负载情况来对workload进行自动的扩缩容。同时以单独的autoscaler项目提供了vpa功能的支持。

该项目提供提供了类似pod水平扩容的机制，跟hpa不同的是，pod的数量由集群中的节点规模来自动扩缩容pod。特别适合负载跟集群规模的变化成正比的服务，比如coredns、nginx ingress等服务。
