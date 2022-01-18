---
title: kubectl常用命令总结
date: 2022-01-18 15:10:14
tags:
---

1. 统计k8s node上的污点信息

```
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints --no-headers
```

2. 查看不ready的pod

```
kubectl get pod --all-namespaces -o wide -w | grep -vE "Com|NAME|Running|1/1|2/2|3/3|4/4"
```

3. pod按照重启次数排序

```
kubectl get pods -A  --sort-by='.status.containerStatuses[0].restartCount' | tail
```
