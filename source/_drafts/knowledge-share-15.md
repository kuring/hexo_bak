title: 技术分享第15期
date: 2022-03-19 22:45:32
tags:
author:
---
# 资源

## 1. [Submariner](https://www.rancher.cn/submariner/)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/how-it-works-submariner.svg)

Rancher开源的一款k8s集群之间的容器网络打通的工具。k8s社区的网络插件中以overlay的网络插件居多，因为overlay的网络对底层物理网络几乎很少有依赖，通常会采用vxlan、IPIP等协议来实现。虽然overlay的网络插件用起来比较方便，但是两个k8s集群的容器网络通常是无法直接通讯，在多k8s集群的应用场景下比较受限。Submariner提供了容器网络的互通方案。 

## 2. [k8e](https://github.com/xiaods/k8e)

k8e为Kubernetes Easy的简写。社区里有k3s和k0s项目来提供了k8s精简版，本项目在k3s的基础之上又进一步进行了裁剪，移除了一些边缘场景的特性。

## 3. [Rancher Desktop](https://rancherdesktop.io/)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/rancher-desktop.png)

k8s的发行版SUSE Rancher提供的k8s的桌面客户端，目前已经发布了1.0.0版本。

## 4. [nginx config](https://nginxconfig.io/)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/nginx-config.jpg)

Nginx作为最流行的负载均衡配置软件之一，有自己的一套配置语法。DigitalOcean提供了界面可以直接进行配置，最终可以一键生成nginx的配置文件。

## 5. [mizu](https://github.com/up9inc/mizu)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/mizu-ui.png)

一款部署在k8s上的流量分析工具，可以认为是k8s版的tcpdump + wireshark。底层的实现也是基于libpcap抓包的方式，可以支持解析HTTP、Redis、Kafka等协议。

## 6. [kube-bench](https://github.com/aquasecurity/kube-bench)

互联网安全中心（Center for Internet Security）针对k8s版本提供了一套安全检查的规范，[约有200多页的pdf文档](https://learn.cisecurity.org/benchmarks)，本项目为针对该规范的实现。仅需要向k8s环境中提交一个job，即可得到最终的安全结果。很多公有云厂商也有自己的实现，比如[阿里云ACK的实现](https://help.aliyun.com/document_detail/207760.html)。

## 7. [virtual-kubelet](https://github.com/virtual-kubelet/virtual-kubelet)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/virtual-kubelet.svg)

virtual kubelet服务通过在k8s集群上创建虚拟node，当一个pod对调度到虚拟node时，virtual kubelet组件以插件的形式提供了不同的实现，可以将pod创建在k8s集群之外。比如，在阿里云的场景下，可以将pod创建到弹性容器实例ECI上面，从而达到弹性的目的。该项目除了用于公有云一些弹性的场景外，还常用于边缘计算的场景。

## 8. [cloudevents](https://cloudevents.io/)

CloudEvents定义了一种通用的方式描述事件数据的规范，由CNCF的Serverless工作组提出。阿里云的事件总线EventBridge基于此规范提供了比较好商业化产品。

# 文章

## 1. [进击的Kubernetes调度系统](https://developer.aliyun.com/article/766273)

该系列一共三篇文档，分别讲解了如下内容：
- [第一篇](https://developer.aliyun.com/article/766273)：k8s 1.16版本引入的Scheduling Framework
- [第二篇](https://developer.aliyun.com/article/766275)：阿里云ACK服务基于Scheduling Framework实现的Gang scheduling
- [第三篇](https://developer.aliyun.com/article/770336)：阿里云ACK服务基于Scheduling Framework实现的支持批任务的Binpack Scheduling
