---
title: 日常工作中经常用到的命令
date: 2019-08-16 20:26:03
tags:
---

shell的命令千千万，工作中总有些命令是经常使用到的，本文记录一些常用到的命令，用于提高效率。

## python

快速开启一个http server `python -m SimpleHTTPServer 8080`

## awk

按照,打印出一每一列 `awk -F, '{for(i=1;i<=NF;i++){print $i;}}'`

