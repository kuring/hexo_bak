title: 技术分享第16期
date: 2022-04-15 19:09:08
tags:
author:
---
# 资源

## [kaniko](https://github.com/GoogleContainerTools/kaniko)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/kaniko.png)

Google开源的一款可以在容器内部通过Dockerfile构建docker镜像的工具。

`docker build`命令可以根据Dockerfile构建出docker镜像，但该操作实际上是由docker daemon进程完成。如果`docker build`命令在docker容器中执行，由于容器中并没有docker daemon进程，因此直接执行`docker build`肯定会失败。

kaniko则重新实现根据Dockerfile构建镜像的功能，使得构建镜像不再依赖docker daemon。随着gitops的流程，CI工具也正逐渐on k8s部署，kaniko正好可以在k8s的环境中根据Dockerfile完成镜像的打包过程，并将镜像推送到镜像仓库中。

## [arc42](https://arc42.org/overview)

架构文档模板

相关链接：https://topic.atatech.org/articles/205083?spm=ata.21736010.0.0.18c23b50NAifwr#tF1lZkHm

## [Carina](https://github.com/carina-io/carina/blob/main/README_zh.md)

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/carina.png)

国内云厂商博云发起的一款基于 Kubernetes CSI 标准实现的存储插件，用来管理本地的存储资源，支持本地磁盘的整盘或者LVM方案来管理存储。同时，还包含了Raid管理、磁盘限速、容灾转移等高级特性。

相关链接：[一篇看懂 Carina 全貌](https://mp.weixin.qq.com/s/-435K5O780NS2gkuLvSr5g)

## [kube-capacity](https://github.com/robscott/kube-capacity)

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/kube-capacity.png)

k8s的命令行工具kubectl用来查看集群的整体资源情况往往操作会比较复杂，可能需要多条命令配合在一起才能拿得到想要的结果。kube-capacity命令行工具用来快速查看集群中的资源使用情况，包括node、pod维度。

相关链接：[Check Kubernetes Resource Requests, Limits, and Utilization with Kube-capacity CLI](https://able8.medium.com/check-kubernetes-resource-reqeusts-limits-and-utilization-with-kube-capacity-cli-b00bf2f4acc9)

## [Kubeprober](https://k.erda.cloud/)

在k8s集群运维的过程中，诊断能力非常重要，可用来快速的定位发现问题。Kubeprober为一款定位为k8s多集群的诊断框架，提供了非常好的扩展性来接入诊断项，诊断结果可以通过grafana来统一展示。

社区里类似的解决方案还有Kubehealthy和Kubeeye。

相关链接：[用更云原生的方式做诊断｜大规模 K8s 集群诊断利器深度解析](https://mp.weixin.qq.com/s/Wte75OfQ7Ihzlm4th-pNYA)


## [Open Policy Agent](https://www.openpolicyagent.org/)

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/opa.png)

OPA为一款开源的基于Rego语言的通用策略引擎，CNCF的毕业项目，可以用来实现一些基于策略的安全防护。比如在k8s中，要求pod的镜像必须为某个特定的registry，用户可以编写策略，一旦pod创建，OPA的gatekeeper组件通过webhook的方式来执行策略校验，一旦校验失败从而到会导致pod创建失败。

比如 [阿里云的ACK的gatekeeper](https://help.aliyun.com/document_detail/180803.html?spm=ata.21736010.0.0.3d7e50fddLMBB9) 就是基于OPA的实现。

## [docker-squash](https://github.com/goldmann/docker-squash)

docker-squash为一款docker镜像压缩工具。在使用Dockerfile来构建镜像时，会产生很多的docker镜像层，当Dockerfile中的命令过多时，会产生大量的docker镜像层，从而导致docker镜像过大。该工具可以将镜像进行按照层合并压缩，从而减小镜像的体积。

## [FlowUs](https://flowus.cn/)

![](https://kuring.oss-cn-beijing.aliyuncs.com/knowledge/flowus.jpg)

FlowUs为国内研发的一款在线编辑器，支持文档、表格和网盘功能，该软件可以实现笔记、项目管理、共享文件等功能，跟蚂蚁集团的产品《[语雀](https://www.yuque.com/)》功能比较类似。但相比语雀做的好的地方在于，FlowUs通过”块编辑器“的方式，在FlowUs看来所有的文档形式都是”块“，作者可以在文档中随意放置各种类型的”块“，在同一个文档中即可以有功能完善的表格，也可以有网盘。而语雀要实现一个相对完整的表格，需要新建一种表格类型的文档，类似于Word和Excel。


# 文章

1. [中美云巨头歧路，中国云未来增长点在哪？](https://mp.weixin.qq.com/s/4ufpUSq2Qn_QV5vIJcPgqg)

文章结合全球的云计算行业，对国内的云计算行业做了非常透彻的分析。”全球云，看中美；中美云，看六大云“，推荐阅读。

2. [程序员必备的思维能力：结构化思维](https://mp.weixin.qq.com/s/F0KoDD9er7MNKYo-5POfsA)

结构化思维不仅对于程序员，对于职场中的很多职业都非常重要，无论是沟通、汇报、晋升，还是写代码结构化思维都非常重要。本文深度剖析了金字塔原理以及如何应用，非常值得一读。