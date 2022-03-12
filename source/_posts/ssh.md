title: ssh协议
tags:
  - 效率
categories: []
date: 2022-03-12 17:55:00
author:
---
# 免密登录

用来两台主机之间的ssh免密操作，步骤比较简单，主要实现如下两个操作：
1. 生成公钥和私钥
2. 将公钥copy到要免密登录的服务器


## 生成公钥和私钥

执行 `ssh-keygen -b 4096 -t rsa` 即可在 ~/.ssh/目录下生成两个文件id_rsa和id_rsa.pub，其中id_rsa为私钥文件，id_rsa.pub为公钥文件。

## 将公钥copy到要免密登录的服务器

执行 `ssh-copy-id $user@$ip` 即可将本地的公钥文件放到放到要免密登录服务器的 $HOME/.ssh/authorized_keys 文件中。至此，免密登录的配置就完成了。