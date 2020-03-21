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

## 使用clusterip访问的情况

通过下面的KUBE-SERVICES链匹配到KUBE-SVC-xxx链，后面的iptabels规则会跟nodeport一致，经过了一次dnat转换，其源ip地址并不会发生变化。

```
-A KUBE-SERVICES ! -s 10.254.0.0/18 -d 192.168.249.119/32 -p tcp -m comment --comment "default/nginx-svc:80 cluster IP" -m tcp --dport 8000 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 192.168.249.119/32 -p tcp -m comment --comment "default/nginx-svc:80 cluster IP" -m tcp --dport 8000 -j KUBE-SVC-Y5VDFIEGM3DY2PZE

# 使用random模块，50%概率进入到KUBE-SEP-JY4YVH4LP7UWS56K链中，50%概率进入到KUBE-SEP-JELAHTLD2S3MLAIG
-A KUBE-SVC-Y5VDFIEGM3DY2PZE -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-JY4YVH4LP7UWS56K
-A KUBE-SVC-Y5VDFIEGM3DY2PZE -j KUBE-SEP-JELAHTLD2S3MLAIG

-A KUBE-SEP-JY4YVH4LP7UWS56K -s 10.254.6.217/32 -j KUBE-MARK-MASQ
# DNAT规则
-A KUBE-SEP-JY4YVH4LP7UWS56K -p tcp -m tcp -j DNAT --to-destination 10.254.6.217:80

-A KUBE-SEP-JELAHTLD2S3MLAIG -s 10.254.9.148/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-JELAHTLD2S3MLAIG -p tcp -m tcp -j DNAT --to-destination 10.254.9.148:80
```

## 使用nodeport访问的情况

k8s针对NodePort创建了KUBE-NODEPORTS链，在包离开宿主机发往目的pod时还会做一次snat，最终pod看到的源ip地址为node的ip。

```
# PREROUTING阶段规则
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx-svc:80" -m tcp --dport 31080 -j KUBE-MARK-MASQ
-A KUBE-NODEPORTS -p tcp -m comment --comment "default/nginx-svc:80" -m tcp --dport 31080 -j KUBE-SVC-Y5VDFIEGM3DY2PZE

# POSTROUTING阶段规则，仅NodePort模式会用到
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
```

上面用到了KUBE-MARK-MASQ链

```
# 设置mark
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
```

KUBE-MARK-MASQ链的作用仅为mark，很多地方都有调用该链，如使用NodePort访问Service的KUBE-NODEPORTS链。

```
# 匹配mark
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
```

上面的匹配mark规则在POSTROUTING阶段，用于匹配mark为0x4000/0x4000的数据包，并进行一次MASQUERADE转换，将ip包替换为宿主上的ip地址。

加入这里不做MASQUERADE，流量发到目的的pod后，pod回包时目的地址为发起端的源地址，而发起端的源地址很可能是在k8s集群外部的，此时pod发回的包是不能回到发起端的。NodePort跟ClusterIP的最大不同就是NodePort的发起端很可能是在集群外部的，从而这里必须做一层SNAT转换。

在上述分析中，访问NodePort类型的Service会经过snat，从而服务端的pod不能获取到正确的客户端ip。可以设置Service的spec.externalTrafficPolicy为Local，此时iptables规则只会将ip包转发给运行在这台宿主机上的pod，而不需要经过snat。pod回包时，直接回复源ip地址即可，此时源ip地址是可达的，因为源ip地址跟宿主机是可达的。如果所在的宿主机上没有pod，那么此时流量就不可以转发，此为限制。

## 使用LoadBalancer类型访问的情况

### externalTrafficPolicy为local

```
-A KUBE-SERVICES -d 10.149.30.186/32 -p tcp -m comment --comment "acs-system/nginx-ingress-lb-cloudbiz:http loadbalancer IP" -m tcp --dport 80 -j KUBE-FW-76HLDRT5IPNSMPF5
-A KUBE-FW-76HLDRT5IPNSMPF5 -m comment --comment "acs-system/nginx-ingress-lb-cloudbiz:http loadbalancer IP" -j KUBE-XLB-76HLDRT5IPNSMPF5
-A KUBE-FW-76HLDRT5IPNSMPF5 -m comment --comment "acs-system/nginx-ingress-lb-cloudbiz:http loadbalancer IP" -j KUBE-MARK-DROP

# 10.149.112.0/23为pod网段
-A KUBE-XLB-76HLDRT5IPNSMPF5 -s 10.149.112.0/23 -m comment --comment "Redirect pods trying to reach external loadbalancer VIP to clusterIP" -j KUBE-SVC-76HLDRT5IPNSMPF5
-A KUBE-XLB-76HLDRT5IPNSMPF5 -m comment --comment "Balancing rule 0 for acs-system/nginx-ingress-lb-cloudbiz:http" -j KUBE-SEP-XZXLBWOKJBSJBGVU

-A KUBE-SVC-76HLDRT5IPNSMPF5 -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-XZXLBWOKJBSJBGVU
-A KUBE-SVC-76HLDRT5IPNSMPF5 -j KUBE-SEP-GP4UCOZEF3X7PGLR

-A KUBE-SEP-XZXLBWOKJBSJBGVU -s 10.149.112.45/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-XZXLBWOKJBSJBGVU -p tcp -m tcp -j DNAT --to-destination 10.149.112.45:80
-A KUBE-SEP-GP4UCOZEF3X7PGLR -s 10.149.112.46/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-GP4UCOZEF3X7PGLR -p tcp -m tcp -j DNAT --to-destination 10.149.112.46:80
```
