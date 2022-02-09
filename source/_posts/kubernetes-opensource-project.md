title: Github Kubernetes组织下开源项目（持续更新）
tags: []
categories: []
date: 2022-02-09 20:12:00
author:
---
在k8s官方的Github kubernetes group下除了k8s的核心组件外，还有很多开源项目，本文用来简要分析这些开源项目的用途。

# node-problem-detector
项目地址：https://github.com/kubernetes/node-problem-detector

k8s的管控组件对于iaas层的node运行状态是完全不感知的，比如节点出现了ntp服务挂掉、硬件告警（cpu、内存、磁盘故障）、内核死锁。node-problem-detector旨在将node节点的问题通知给k8s组件，以DaemonSet的方式部署在所有的k8s节点上。

上报故障的方式支持如下两种方式：
- 对于永久性故障，通过修改node status中的condition上报给apiserver
- 对于临时性故障，通过Event的方式上报

node-problem-detector在将节点的故障信息上报给k8s后，通常会配合一些自愈系统搭配使用，比如Draino和Descheduler 。

# Descheduler
项目地址：https://github.com/kubernetes-sigs/descheduler

k8s的pod调度完全动态的，kube-scheduler组件在调度pod的时候会根据当时k8s集群的运行时环境来决定pod可以调度的节点，可以保证pod的调度在当时是最优的。但是随着的推移，比如环境中增加了新的node、创建了一批亲和节点的pod，都有可能会导致如果相同的pod再重新调度会到其他的节点上。但k8s的设计是，一旦pod调度完成后，就不会再重新调度。

Descheduler组件用来解决pod的重新调度问题，可以根据配置的一系列的规则来触发驱逐pod，让pod可以重新调度，从而使k8s集群内的pod尽可能达到最优状态，有点类似于计算机在运行了一段时间后的磁盘脆片整理功能。Descheduler组件可以以job、cronjob或者deployment的方式运行在k8s集群中。

# autoscaler
项目地址：https://github.com/kubernetes/autoscaler
