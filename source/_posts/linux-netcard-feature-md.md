---
title: Linux网络接口特性
date: 2020-08-04 00:48:45
tags:
---

## MTU

MTU是指一个以太网帧能够携带的最大数据部分的大小，并不包含以太网的头部部分。一般情况下MTU的值为1500字节。

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/mtu1.png)

当指定的数据包大小超过MTU值时，ip层会根据当前的mtu值对超过数据包进行分片，并会设置ip层头部的More Fragments标志位，并会设置Fragment offset属性，即分片的第二个以及后续的数据包会增加offset，第一个数据包的offset值为0。接收方会根据ip头部的More Fragment标志位和Fragment offset属性来进行切片的重组。

如果手工将发送方的MTU值设置为较大值，比如9000（巨型帧），如果发送方设置了不分片（ip头部的Don't fragment），此时如果发送的链路上有地方不支持该MTU，报文就会被丢弃。

## offload特性

执行 `ethtool -k ${device}` 可以看到很多跟网络接口相关的特性，这些特性的目的是为了提升网络的收发性能。TSO、UFO和GSO是对应网络发送，LRO、GRO对应网络接收。

执行`ethtool -K ${device} gro off/on` 来开启或者关闭相关的特性。

### LRO(Large Receive Offload)

通过将接收的多个tcp segment聚合为一个大的tcp包，然后传送给网络协议栈处理，以减少上层网络协议栈的处理开销。

但由于tcp segment并不是在同一时刻到达网卡，因此组装起来就会变得比较困难。

由于LRO的一些局限性，在最新的网络上，该功能已经删除。

### GRO(Generic Receive Offload)

GRO是LRO的升级版，正在逐渐取代LRO。运行与内核态，不再依赖于硬件。

## 参考文章

- [关于MTU，这里也许有你不知道的地方](https://segmentfault.com/a/1190000019206098)
- [常见网络加速技术浅谈](https://zhuanlan.zhihu.com/p/44683790)
