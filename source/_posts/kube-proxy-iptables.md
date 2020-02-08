---
title: kube-proxy iptables规则分析
date: 2020-02-08 12:10:33
tags:
---

kube-proxy默认使用iptables规则来做k8s集群内部的负载均衡，本文通过例子来分析创建的iptabels规则。

主要的自定义链涉及到一下一些：

- KUBE-NODEPORTS: 用来匹配nodeport端口号，并将规则转发到KUBE-SVC-xxx。一个NodePort类型的Service一条。
- KUBE-SERVICES： 访问集群内服务的CLusterIP数据包入口，根据匹配到的目标ip+port将数据包分发到相应的KUBE-SVC-xxx链上。一个Service对应一条规则。
- KUBE-SVC-xxx：相当于是负载均衡，将流量利用random模块均分到KUBE-SEP-xxx链上。
- KUBE-SEP-xxx：通过dnat规则将连接的目的地址和端口号做dnat，从Service的ClusterIP或者NodePort转换为后端的pod ip
- KUBE-MARK-MASQ: 使用mark命令，对数据包设置标记0x4000/0x4000。在KUBE-POSTROUTING链上有MARK标记的数据包进行一次MASQUERADE，即SNAT，会用节点ip替换源ip地址。

## 环境准备

创建nginx deployment

```yaml
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    app: nginx-svc
    version: nginx
  name: nginx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-svc
  template:
    metadata:
      labels:
        app: nginx-svc
        version: nginx
    spec:
      containers:
        - image: 'nginx:1.9.0'
          name: nginx
          ports:
            - containerPort: 443
              protocol: TCP
            - containerPort: 80
              protocol: TCP
```

创建service对象

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  namespace: default
spec:
  ports:
    - name: '80'
      port: 8000
      protocol: TCP
      targetPort: 80
      nodePort: 31080
  selector:
    app: nginx-svc
  sessionAffinity: None
  type: NodePort
```

提交后创建出来的信息如下：

- Service ClusterIP：192.168.249.119
- nginx pod的两个ip地址：10.254.9.148 10.254.6.217

## 使用nodeport访问的情况

k8s针对NodePort创建了KUBE-NODEPORTS链

```
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx-svc:80" -m tcp --dport 31080 -j KUBE-MARK-MASQ
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx-svc:80" -m tcp --dport 31080 -j KUBE-SVC-Y5VDFIEGM3DY2PZE

# 使用random模块，50%概率进入到KUBE-SEP-JY4YVH4LP7UWS56K链中，50%概率进入到KUBE-SEP-JELAHTLD2S3MLAIG
-A KUBE-SVC-Y5VDFIEGM3DY2PZE -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-JY4YVH4LP7UWS56K
-A KUBE-SVC-Y5VDFIEGM3DY2PZE -j KUBE-SEP-JELAHTLD2S3MLAIG

-A KUBE-SEP-JY4YVH4LP7UWS56K -s 10.254.6.217/32 -j KUBE-MARK-MASQ
# DNAT规则
-A KUBE-SEP-JY4YVH4LP7UWS56K -p tcp -m tcp -j DNAT --to-destination 10.254.6.217:80

-A KUBE-SEP-JELAHTLD2S3MLAIG -s 10.254.9.148/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-JELAHTLD2S3MLAIG -p tcp -m tcp -j DNAT --to-destination 10.254.9.148:80
```

其中这些规则的执行是在PREROUTING阶段。

## 使用clusterip访问的情况

通过下面的KUBE-SERVICES链匹配到KUBE-SVC-xxx链，后面的iptabels链跟上面nodeport一致

```
-A KUBE-SERVICES ! -s 10.254.0.0/18 -d 192.168.249.119/32 -p tcp -m comment --comment "default/nginx-svc:80 cluster IP" -m tcp --dport 8000 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 192.168.249.119/32 -p tcp -m comment --comment "default/nginx-svc:80 cluster IP" -m tcp --dport 8000 -j KUBE-SVC-Y5VDFIEGM3DY2PZE
```

## 关于KUBE-MARK-MASQ链的说明

```
# 设置mark
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
```

KUBE-MARK-MASQ链的作用仅为mark，很多地方都有调用该链，如使用ClusterIP访问Service的KUBE-SERVICES链，使用NodePort访问Service的KUBE-NODEPORTS链。

```
# 匹配mark
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
```

上面的匹配mark规则在POSTROUTING阶段，用于匹配mark为0x4000/0x4000的数据包，并进行一次MASQUERADE转换，将ip包替换为宿主上的ip地址。

这里之所以要做MASQUERADE，还是以上面的例子进行说明。

环境信息说明如下：

- Service ClusterIP：192.168.249.119
- nginx pod的两个ip地址：10.254.9.148 10.254.6.217
- 访问client：使用pod ip 10.254.6.1
- 访问client所在的宿主机ip：172.16.3.1

先看下假设没有配置MASQUERADE的情况下的网络流量，此时去向网络流量如下图所示：

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/kube-proxy-iptables1.png)

当nginx pod 10.254.9.148接收到包后，回复的包跟接收的到源ip和目的ip恰好是相反的。包到达host 1后，由于目的ip为pod ip，会将包直接发给pod，pod由于识别不了该包，会将该包直接丢弃掉。包的回向如下图所示：

![](https://kuring.oss-cn-beijing.aliyuncs.com/common/kube-proxy-iptables2.png)

为了解决该问题，需要将发出去的包再做一次MASQUERADE，即SNAT。这样回向的包，目的地址变为宿主机的ip地址172.16.3.1。

