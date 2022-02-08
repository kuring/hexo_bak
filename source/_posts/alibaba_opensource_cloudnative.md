title: 阿里巴巴开源云原生项目分析（持续更新）
tags: []
categories: []
date: 2022-02-08 21:33:00
author:
---
# 集群镜像sealer
项目地址：https://github.com/alibaba/sealer

相关资料：[集群镜像：实现高效的分布式应用交付](https://mp.weixin.qq.com/s/0SBslzaMWtqn9H8Q57urNA)

![https://user-images.githubusercontent.com/8912557/117400612-97cf3a00-af35-11eb-90b9-f5dc8e8117b5.png](https://kuring.oss-cn-beijing.aliyuncs.com/common/sealer.png)

当前的应用发布经历了三个阶段：
- 阶段一 裸部署在物理机或者vm上。直接裸部署在机器上的进程，存在操作系统、软件包的依赖问题，比如要部署一个python应用，那么需要机器上必须要包含对应版本的python运行环境以及应用依赖的所有包。
- 阶段二 通过镜像的方式部署在宿主机上。docker通过镜像的方式将应用以及依赖打包到一起，解决了单个应用的依赖问题。
- 阶段三 通过k8s的方式来标准化部署。在k8s时代，可以将应用直接部署到k8s集群上，将应用的发布标准化，实现应用的跨机器部署。

在阶段三中，应用发布到k8s集群后，应用会对k8s集群有依赖，比如k8s管控组件的配置、使用的网络插件、应用的部署yaml文件，对镜像仓库和dockerd的配置也有所依赖。当前绝大多数应用发布是跟k8s集群部署完全独立的，即先部署k8s集群，然后再部署应用，跟阶段一的发布单机应用模式比较类似，先安装python运行环境，然后再启动应用。

sealer项目是个非常有意思的开源项目，旨在解决k8s集群连同应用发布的自动化问题，可以实现类似docker镜像的方式将整个k8s集群连同应用一起打包成集群镜像，有了集群镜像后既可以标准化的发布到应用到各个地方。sealer深受docker的启发，提出的很多概念跟docker非常类似。

- Kubefile概念跟Dockerfile非常类似，且可以执行sealer build命令打包成集群镜像，语法也类似于Dockerfile。
- CloudImage：集群镜像，将Kubefile打包后的产物，类比与dockerimage。基础集群镜像通常为裸k8s集群，跟docker基础镜像为裸操作系统一致。
- Clusterfile：要想运行CloudImage，需要配合Clusterfile文件来启动，类似于Docker Compose。Clusterfile跟Docker Compose一致，并不是必须的，也可以通过sealer run的方式来启动集群镜像。

sealer要实现上述功能需要实现将k8s集群中的所有用到镜像全部打包到一个集群镜像中。