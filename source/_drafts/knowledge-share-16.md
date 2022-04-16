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


# 文章

1. [中美云巨头歧路，中国云未来增长点在哪？](https://mp.weixin.qq.com/s/4ufpUSq2Qn_QV5vIJcPgqg)

文章结合全球的云计算行业，对国内的云计算行业做了非常透彻的分析。”全球云，看中美；中美云，看六大云“，推荐阅读。