---
type : post
title : Kubernetes 学习笔记-问题记录
categories: [Kubernetes,] 
date : 2020-09-03
url: /posts/2020-09-03-k8s-issu.html 
tags : [Kubernetes, docker]
---

> 本篇为k8s学习笔记问题记录。基础概念和搭建可参考之前文章 []()

## 问题汇总

上文记录了我搭建K8S集群的过程，这里记录些问题和解决方案便于查阅。

**1/ 各组件启动失败时，如何方便的查看错误？**

可使用命令 `systemctl status <组件名>` 或 `journalctl -xefu <组件名>`查看日志。

**2/ 注意cgroup启动问题**

```
failed to create kubelet: misconfiguration: kubelet cgroup driver: "cgroupfs" is different from docker cgroup driver: "systemd"
```
kubelet 默认使用 `cgroupfs` 启动，可修改为docker 的`systemd`， 或修改docker 启动为 `cgroupfs`。

docker 修改的地方为 /etc/docker/daemon.json

```
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```

kuberlet 可修改systemd 的service中启动命令增加`--cgroup-driver`参数：

```
# 可指定启动参数 
DOCKER_CGROUPS=$(docker info | grep 'Cgroup' | cut -d' ' -f3)

--cgroup-driver=$DOCKER_CGROUPS

```

**3/ 节点删除后如何重新授权？**

节点删除后，重启 kubelet。在Master 端是看不到申请信息的，需要将上次申请的证书删除，再重启。

```bash 
# master
kubectl delete node node01

# node01 
rm -f /opt/kubernetes/ssl/kubelet*
systemctl restart kubelet 
```

**4/ 排查pod无法启动的思路**

```bash 
# 1. 先查看pod的最近的操作
kubectl describe pod <pod-name> -n kube-system 

# 2. 查看pod 的日志
kubectl logs pod <pod-name>
```