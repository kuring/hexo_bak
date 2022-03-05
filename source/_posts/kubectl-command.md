title: kubectl常用命令
date: 2022-01-18 15:10:14
tags:
---
本文记录常用的kubectl命令，不定期更新。

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

4. kubectl proxy命令代理k8s apiserver

该命令经常用在开发的场景下，用来测试k8s api的结果。执行如下命令即可在本地127.0.0.1开启10999端口。

```
kubectl proxy --port=10999
```

在本地即可通过curl的方式来访问k8s的apiserver，而无需考虑鉴权问题。例如，`curl http://127.0.0.1:10999/apis/batch/v1`，即可直接返回结果。

5. --raw命令

该命令经常用在开发的场景下，用来测试k8s api的结果。执行如下的命令，即可返回json格式的结果。

```
kubectl get --raw /apis/batch/v1
```