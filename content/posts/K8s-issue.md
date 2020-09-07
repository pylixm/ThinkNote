---
type : posts
title : Kubernetes 学习笔记 - 问题记录
categories: [Kubernetes,] 
date : 2020-09-03
url: /posts/2020-09-03-k8s-issu.html 
tags : [Kubernetes, docker]
---

> 本篇为k8s学习笔记问题记录。基础概念和搭建可参考之前文章 [Kubernetes 学习笔记-基础篇](https://pylixm.cc/posts/2020-08-20-k8s-base.html) 和 [Kubernetes 学习笔记-集群搭建篇(二进制方式)](https://pylixm.cc/posts/2020-09-01-k8s-build.html)。

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

**5/ 解决Dashboard 2.0 chrome浏览器不能访问的问题**

```bash 
mkdir key && cd key
# 1 生成证书
openssl genrsa -out dashboard.key 2048
openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=kubernetes-dashboard-certs'
openssl x509 -req -in dashboard.csr -signkey dashboard.key -out dashboard.crt
# 2 删除原有的证书secret
kubectl delete secret kubernetes-dashboard-certs -n kube-system
# 3 创建新的证书secret
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kube-system
# 4 查看dashboard pod，v2.0是 -n kubernetes-dashboard
kubectl get pod -n kube-system
# 5 重启dashboard pod，v2.0是 -n kubernetes-dashboard
kubectl delete pod <pod name> -n kube-system
```

**6/ 如何彻底的删除一个pod?**

K8S中pod 是有`deployments`来发布的，所以直接删除pod后，k8s无法识别是人为还是故障，它会根据`deployments` 描述的信息，重新启动一个pod。所以要删除pod 时，直接删除对应的 `deployments `，pod会自动删除。

```bash 
kubectl delete deployment <deployment_name> -n <namespace>
```

**7/ 节点维护时，如何手动驱赶pod?**

```bash 
# 1、标记节点不可调度
kubectl cordon <node name>
# 2、手动迁移pod 
kubectl drain <node name> --delete-local-data --ignore-daemonsets --force

# 3、带节点维护完成之后，恢复可调度
kubectl uncordon <node name>
```