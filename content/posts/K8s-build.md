---
type : post
title : Kubernetes 学习笔记-集群搭建篇(二进制方式)
categories: [Kubernetes,] 
date : 2020-09-01
url: /posts/2020-09-01-k8s-build.html 
tags : [Kubernetes, docker]
---

> 本篇记录我集群搭建的过程和问题，目标是可以根据本篇文章搭建自己生产可用的K8S集群。对于K8S的一些概念理解，可参考我之前的笔记[Kubernetes 学习笔记-基础篇](https://pylixm.cc/posts/2020-08-20-k8s-base.html)。

## 环境准备

容器环境对Linux的系统内核有一定的要求， `kernel 3.10` 是当前Docker 19 可以稳定运行的最小的Linux内核版本。Docker 中应用了很多内核中的新功能，经过大量的实践证明，使用你当前发行版本Linux的最新稳定的内核是最佳的选择。

通过下边的脚本，可以检测依赖环境的可用性：

> https://github.com/docker/docker/blob/master/contrib/check-config.sh


K8S 官方建议集群硬件最小配置为，2G 内存，2个cpu, 30G硬盘。若集群仅作为学习使用，官方提供了 `Minikube`和`Kind`两种方式，可安装简易版的K8S，来熟悉了解K8S的各种组件和功能。针对Mac 用户，`Docker for Mac`的客户端也集成了K8S的功能，也可启用来体验。

- `Minikube` 和 `Kind` 方式安装K8S [安装文档](https://kubernetes.io/docs/setup/learning-environment/);
- `Docker for Mac` [启用文档](https://docs.docker.com/docker-for-mac/#kubernetes);

本次目标搭建生产可用的集群，环境准备如下：

- 6台Liunux机器，CentOS 7.8, Kernel 3.10.0-1127.18.2.el7.x86_64 
  - 192.168.10.11
  - 192.168.10.12
  - 192.168.10.13
  - 192.168.10.14
  - 192.168.10.15
  - 192.168.10.16
- Docker: 18.09.9 
- Kubernetes: 1.16.14 (考虑到内核版本比较低，选择了较低版本，k8s 1.18 部署相同)
- ETCD: 3.4.9

### 环境规划

规划K8S的各组件机器如下：

- ETCD 
  - 192.168.10.14
  - 192.168.10.15
  - 192.168.10.16

- K8S Master
  - 192.168.10.11  host: 10-11-master
  - 192.168.10.12  host: 10-12-master
  - 192.168.10.13  host: 10-13-master

- K8S Node
  - 192.168.10.14  host: 10-14-node
  - 192.168.10.15  host: 10-15-node
  - 192.168.10.16  host: 10-16-node

- Nginx + Keepalived 
  - 192.168.10.14
  - 192.168.10.15

这里Node和高可用组件都共用了ETCD的机器，这里仅作为演示说明，真实生产环境中建议都使用单独的机器部署，以免组件或机器故障相互影响。

### 环境初始化

以下操作，Master和Node机器需要执行。

```bash
# 设置系统host，如192.169.10.11 host 为 10-11-master。其他机器修改方式相同。
$ hostnamectl  set-hostname  10-11-master
$ echo "127.0.0.1   $(hostname)" >> /etc/hosts

# 升级系统内核
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak 
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
yum clean all
yum -y update

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭swap 
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

# 关闭SeLinux 
setenforce  0 
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux 
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config 
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux 
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config 


# 设置内核参数
cat <<EOF > /etc/sysctl.d/k8s.conf

net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10
EOF

modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf
ls /proc/sys/net/bridge

# 配置资源限制
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 65536"  >> /etc/security/limits.conf
echo "* hard nproc 65536"  >> /etc/security/limits.conf
echo "* soft memlock  unlimited"  >> /etc/security/limits.conf
echo "* hard memlock  unlimited"  >> /etc/security/limits.conf

# 依赖安装
yum install -y epel-release
yum install -y yum-utils device-mapper-persistent-data lvm2 net-tools conntrack-tools wget vim ntpdate libseccomp libtool-ltdl

# 安装Docker  
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache fast
yum -y install docker-ce-18.09.9 docker-ce-cli-18.09.9
systemctl enable docker.service
systemctl start docker.service
systemctl stop docker.service
cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "registry-mirrors": [
      "https://4xr1qpsp.mirror.aliyuncs.com",
      "https://dockerhub.azk8s.cn",
      "http://hub-mirror.c.163.com",
      "https://registry.docker-cn.com"
  ],
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file":"5"
  }
}
EOF 

systemctl daemon-reload
systemctl start docker

```

## 组件安装 

机器环境初始化好之后，开始搭建K8S。主要有两种搭建方式：

- kubeadm：官方提供的安装工具，除管理容器的组件kubelet外，其他组件均以容器的形式启动。可通过 `kubeadm init` 和 `kubeadm join`来快速实现K8S集群的搭建。官方地址：https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/ 。 更加详细的安装步骤，可参考扩展阅读1。

- 二进制方式搭建：K8S 的各组件都是使用Go语言开发的，发布运行都是编译好的二进制文件。该方式需要自己来安装每个组件，自己编写配置文件和管理启动文件。

初学者，本着学习的目的，本文记录第二种安装方式，以便熟悉K8S的各组件。老手完全可以使用 kubeadm 来快速搭建一个生产可用的集群。

在搭建集群之前，回忆下K8S的各组件。

![](https://gitee.com/pylixm/picture/raw/master/2020-9-1/1598946269456-architecture.png)
(图片来源网络)

那我们梳理部署组件情况如下：

- 单独集群部署：
  - etcd 保存了整个集群的状态；

- Master 部署：
  - controller manager 负责维护集群的状态，比如故障检测、自动扩展、滚动更新等；
  - scheduler 负责资源的调度，按照预定的调度策略将Pod调度到相应的机器上；
  - apiserver 提供了资源操作的唯一入口，并提供认证、授权、访问控制、API注册和发现等机制；

- Node 部署：
  - kubelet 负责维护容器的生命周期，同时也负责容器卷插件Volume（CVI）和容器网络插件（CNI）的管理；
  - kube-proxy 负责为Service提供cluster内部的服务发现和负载均衡；
  - Container runtime 负责镜像管理以及Pod和容器的真正运行（CRI）；

下面开始。

### 1/ ETCD 集群的搭建

ETCD主要用来保存集群状态和资源对象数据。使用kubeadm 安装时，默认`etcd`集群和Master节点是在一块的。为提高可用性减少故障影响，建议将`etcd`单独部署一个集群，方便管理维护。

#### 1.1/ 签发证书

为提高安全性，统一使用ssl加密。可使用自签证书，我们使用 cfssl 工具来生成证书。

```bash
# 下载cfssl 二进制文件
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

# 增加执行权限
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64

# 移动到可执行目录
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```

生成根证书

```
# 创建目录存放证书文件
mkdir -p /opt/ssl/{etcd,k8s}

# 创建根证书配置文件， 有效期为87600h(10年)。
cd /opt/ssl/etcd
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "www": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF

cat > ca-csr.json << EOF
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF

# 生成证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

签发etcd https 证书

```bash
cat > server-csr.json << EOF
{
    "CN": "etcd",
    "hosts": [
    "192.168.10.14",
    "192.168.10.15",
    "192.168.10.16"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing"
        }
    ]
}
EOF
```

> hosts 为etcd的集群节点ip, 改成你实际的ip即可。


#### 1.2/ etcd 集群搭建

下载etcd二进制文件到三台事先准备好的机器，编写配置文件和启动管理文件。

```bash
# 创建etcd目录
mkdir -p /opt/etcd/{bin,cfg,ssl}

# 复制生成的证书到etcd证书目录
cp /opt/ssl/etcd/ca*.pem /opt/etcd/ssl/
cp /opt/ssl/etcd/server*.pem /opt/etcd/ssl/


# 配置文件
wget https://github.com/etcd-io/etcd/releases/download/v3.4.9/etcd-v3.4.9-linux-amd64.tar.gz
tar zxvf etcd-v3.4.9-linux-amd64.tar.gz
cd etcd-v3.4.9-linux-amd64
cp -a etcd etcdctl /opt/etcd/bin/

cat > /opt/etcd/cfg/etcd.conf << EOF
#[Member]
ETCD_NAME="etcd-1"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.10.14:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.14:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.14:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.14:2379"
ETCD_INITIAL_CLUSTER="etcd-1=https://192.168.10.14:2380,etcd-2=https://192.168.10.15:2380,etcd-3=https://192.168.10.16:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

```

- ETCD_NAME：节点名称，集群中唯一
- ETCD_DATA_DIR：数据目录
- ETCD_LISTEN_PEER_URLS：集群通信监听地址
- ETCD_LISTEN_CLIENT_URLS：客户端访问监听地址
- ETCD_INITIAL_ADVERTISE_PEER_URLS：集群通告地址
- ETCD_ADVERTISE_CLIENT_URLS：客户端通告地址
- ETCD_INITIAL_CLUSTER：集群节点地址
- ETCD_INITIAL_CLUSTER_TOKEN：集群Token
- ETCD_INITIAL_CLUSTER_STATE：加入集群的当前状态，new是新集群，existing表示加入已有集群

```bash
# 编写启动管理文件

cat > /usr/lib/systemd/system/etcd.service << EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/opt/etcd/cfg/etcd.conf
ExecStart=/opt/etcd/bin/etcd \
--enable-v2 \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--peer-cert-file=/opt/etcd/ssl/server.pem \
--peer-key-file=/opt/etcd/ssl/server-key.pem \
--trusted-ca-file=/opt/etcd/ssl/ca.pem \
--peer-trusted-ca-file=/opt/etcd/ssl/ca.pem \
--logger=zap
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# 启动
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd
```

复制etcd文件（/opt/etcd/下的所有文件，service文件）到其他两个节点，并修改`/opt/etcd/cfg/etcd.conf`文件中ip为对应节点ip，启动即可。

最后，查看节点状态。

```bash
ETCDCTL_API=3 /opt/etcd/bin/etcdctl --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints="https://192.168.10.14:2379,https://192.168.10.15:2379,https://192.168.10.16:2379" endpoint health

https://192.168.10.14:2379 is healthy: successfully committed proposal: took = 12.762896ms
https://192.168.10.15:2379 is healthy: successfully committed proposal: took = 12.974284ms
https://192.168.10.16:2379 is healthy: successfully committed proposal: took = 12.996147ms
```

至此，etcd集群搭建完成。

### 2/ Kubernetes Master 节点部署

#### 2.1/ 签发证书

生成根证书

```bash
cd /opt/ssl/k8s/
cat > ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
cat > ca-csr.json << EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF

# 生成证书
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
```

签发apiserver的https证书

```bash
cd /opt/ssl/k8s
cat > server-csr.json << EOF
{
    "CN": "kubernetes",
    "hosts": [
      "10.10.0.1",
      "127.0.0.1",
      "192.168.10.11",
      "192.168.10.12",
      "192.168.10.13",
      "192.168.10.14",
      "192.168.10.15",
      "192.168.10.16",
      "192.168.10.17",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
```

> hosts字段中IP为所有Master/LB/VIP 的ip，需要访问apiserver 的节点ip 建议都写上。

```
# 生成证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server

```

#### 2.2/ apiserver 部署

可从这里 https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG 找到你需要的版本的二进制安装包。直接下载server包即可，其中包含有 `apiserver`、`controller manager`和`scheduler`的二进制文件。
`apiserver` 部署步骤如下：

```bash
# 获取二进制文件
wget https://dl.k8s.io/v1.16.14/kubernetes-server-linux-amd64.tar.gz

mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs} 
tar zxvf kubernetes-server-linux-amd64.tar.gz
cd kubernetes/server/bin
cp kube-apiserver kube-scheduler kube-controller-manager /opt/kubernetes/bin
cp kubectl /usr/bin/

# 创建配置文件
cp /opt/ssl/k8s/ca*pem /opt/ssl/k8s/server*pem /opt/kubernetes/ssl/

cat > /opt/kubernetes/cfg/kube-apiserver.conf << EOF
KUBE_APISERVER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--etcd-servers=https://192.168.10.14:2379,https://192.168.10.15:2379,https://192.168.10.16:2379 \\
--bind-address=192.168.10.11 \\
--secure-port=6443 \\
--advertise-address=192.168.10.11 \\
--allow-privileged=true \\
--service-cluster-ip-range=10.10.0.0/24 \\
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \\
--authorization-mode=RBAC,Node \\
--enable-bootstrap-token-auth=true \\
--token-auth-file=/opt/kubernetes/cfg/token.csv \\
--service-node-port-range=30000-32767 \\
--kubelet-client-certificate=/opt/kubernetes/ssl/server.pem \\
--kubelet-client-key=/opt/kubernetes/ssl/server-key.pem \\
--tls-cert-file=/opt/kubernetes/ssl/server.pem  \\
--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \\
--client-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--etcd-cafile=/opt/etcd/ssl/ca.pem \\
--etcd-certfile=/opt/etcd/ssl/server.pem \\
--etcd-keyfile=/opt/etcd/ssl/server-key.pem \\
--audit-log-maxage=30 \\
--audit-log-maxbackup=3 \\
--audit-log-maxsize=100 \\
--audit-log-path=/opt/kubernetes/logs/k8s-audit.log"
EOF

```

- logtostderr：启用日志
- v：日志等级
- log-dir：日志目录
- etcd-servers：etcd集群地址
- bind-address：监听地址
- secure-port：https安全端口
- advertise-address：集群通告地址
- allow-privileged：启用授权
- service-cluster-ip-range：Service虚拟IP地址段
- enable-admission-plugins：准入控制模块
- authorization-mode：认证授权，启用RBAC授权和节点自管理
- enable-bootstrap-token-auth：启用TLS bootstrap机制
- token-auth-file：bootstrap token文件
- service-node-port-range：Service nodeport类型默认分配端口范围
- kubelet-client-xxx：apiserver访问kubelet客户端证书
- tls-xxx-file：apiserver https证书
- etcd-xxxfile：连接Etcd集群证书
- audit-log-xxx：审计日志

Master apiserver启用TLS认证后，Node节点`kubelet`和`kube-proxy`要与`kube-apiserver`进行通信，必须使用CA签发的有效证书才可以，当Node节点很多时，这种客户端证书颁发需要大量工作，同样也会增加集群扩展复杂度。为了简化流程，Kubernetes引入了`TLS bootstraping`机制来自动颁发客户端证书，`kubelet`会以一个低权限用户自动向`apiserver`申请证书，`kubelet`的证书由`apiserver`动态签署。所以强烈建议在Node上使用这种方式，目前主要用于`kubelet`，`kube-proxy`还是由我们统一颁发一个证书。

```bash
# 生成一个随机token 
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
ebe4f1e22044e23638394dd24d4aff49
# 创建token 文件， 该文件在 apiserver 参数 token-auth-file 参数使用
cat > /opt/kubernetes/cfg/token.csv << EOF
ebe4f1e22044e23638394dd24d4aff49,kubelet-bootstrap,10001,"system:node-bootstrapper"
EOF
```

创建服务管理配置文件

```bash 
cat > /usr/lib/systemd/system/kube-apiserver.service << EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-apiserver.conf
ExecStart=/opt/kubernetes/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

启动

```bash
systemctl daemon-reload
systemctl start kube-apiserver
systemctl enable kube-apiserver
```

授权kubelet-bootstrap 用户允许请求证书，kubelet使用该用户来请求apiserver证书，该用户稍后部署kubelet时会配置。

```bash
kubectl create clusterrolebinding kubelet-bootstrap \
--clusterrole=system:node-bootstrapper \
--user=kubelet-bootstrap
```

#### 2.3/ kube-controller-manager 部署

创建配置文件

```bash
cat > /opt/kubernetes/cfg/kube-controller-manager.conf << EOF
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--leader-elect=true \\
--master=127.0.0.1:8080 \\
--bind-address=127.0.0.1 \\
--service-cluster-ip-range=10.10.0.0/24 \\
--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \\
--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \\
--root-ca-file=/opt/kubernetes/ssl/ca.pem \\
--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \\
--experimental-cluster-signing-duration=87600h0m0s"
EOF
```

- master：通过本地端口8080连接apiserver。
- leader-elect：当该组件启动多个时，自动选举（HA）
- cluster-signing-cert-file/–cluster-signing-key-file：自动为kubelet颁发证书的CA，与apiserver保持一致

启动管理配置文件

```bash
cat > /usr/lib/systemd/system/kube-controller-manager.service << EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-controller-manager.conf
ExecStart=/opt/kubernetes/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

启动

```bash 
systemctl daemon-reload
systemctl start kube-controller-manager
systemctl enable kube-controller-manager
```

#### 2.4/ kube-scheduler 部署

```bash
cat > /opt/kubernetes/cfg/kube-scheduler.conf << EOF
KUBE_SCHEDULER_OPTS="--logtostderr=false \
--v=2 \
--log-dir=/opt/kubernetes/logs \
--leader-elect=true \
--master=127.0.0.1:8080 \
--bind-address=127.0.0.1"
EOF
```

- master：通过本地端口8080连接apiserver。
- leader-elect：当该组件启动多个时，自动选举（HA）

启动管理配置文件

```bash
cat > /usr/lib/systemd/system/kube-scheduler.service << EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-scheduler.conf
ExecStart=/opt/kubernetes/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

启动

```bash
systemctl daemon-reload
systemctl start kube-scheduler
systemctl enable kube-scheduler
```

#### 2.5/ 部署其他两个Master节点

```bash
# 创建etcd 证书目录
mkdir -p /opt/etcd/ssl

# 复制 apiserver controller-manager scheduler 配置文件及二进制文件
scp -r /opt/kubernetes root@192.168.10.12:/opt
# 复制etcd 证书文件
scp -r /opt/etcd/ssl root@192.168.10.12:/opt/etcd
# 复制 systemd 管理文件
scp /usr/lib/systemd/system/kube* root@192.168.10.12:/usr/lib/systemd/system
# 复制ctl 二进制文件
scp /usr/bin/kubectl  root@192.168.10.12:/usr/bin

# 修改配置文件为对应ip 
vi /opt/kubernetes/cfg/kube-apiserver.conf 
...
--bind-address=192.168.10.12 \
--advertise-address=192.168.10.12 \
...

# 启动
systemctl daemon-reload
systemctl start kube-apiserver
systemctl start kube-controller-manager
systemctl start kube-scheduler

systemctl enable kube-apiserver
systemctl enable kube-controller-manager
systemctl enable kube-scheduler
```

至此，Master节点部署完成。


### 3/ Kubernetes Node 节点部署

创建目标，并复制组件二进制文件。

```bash
# 创建kubernetes目录
mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs} 
# 复制二进制文件
scp /root/kubernetes/server/bin/kubelet  root@192.168.10.14:/opt/kubernetes/bin
scp /root/kubernetes/server/bin/kube-proxy  root@192.168.10.14:/opt/kubernetes/bin
scp /root/kubernetes/server/bin/kubectl  root@192.168.10.14:/bin/

chmod +x /opt/kubernetes/bin/*
chmod +x /bin/kubectl 

# 复制根证书
scp /opt/kubernetes/ssl/ca.pem  root@192.168.10.14:/opt/kubernetes/ssl

```

#### 3.1/ kubelet 部署

创建配置文件

```
cat > /opt/kubernetes/cfg/kubelet.conf << EOF
KUBELET_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--hostname-override=10-14-node \\
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \\
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \\
--config=/opt/kubernetes/cfg/kubelet-config.yml \\
--cert-dir=/opt/kubernetes/ssl \\
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
EOF
```

- hostname-override：显示名称，集群中唯一
- network-plugin：启用CNI
- kubeconfig：自动生成的配置文件，后面用于连接apiserver
- bootstrap-kubeconfig：首次启动向apiserver申请证书
- config：配置参数文件
- cert-dir：kubelet证书生成目录
- pod-infra-container-image：管理Pod网络容器的镜像

配置参数文件。

```bash
cat > /opt/kubernetes/cfg/kubelet-config.yml << EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
port: 10250
readOnlyPort: 10255
cgroupDriver: systemd
clusterDNS:
- 10.10.0.2
clusterDomain: cluster.local 
failSwapOn: false
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /opt/kubernetes/ssl/ca.pem
authorization:  
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
maxOpenFiles: 1000000
maxPods: 110
EOF
```

- cgroupDriver: 需要与Docker的cgroup启动一致，这里都是用systemd。
- clusterDNS: DNS 服务器地址，用来做服务名称和ip的解析用。service启动会创建一条服务名和ip的解析，直接使用service名称就能访问服务，以达到服务发现的效果。这里先填上ip,后边会部署这个DNS服务。

生成 kubelet bootstrap kubeconfig 配置文件, 用来申请apiserver 证书。

```bash
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=https://192.168.10.12:6443 \
  --kubeconfig=bootstrap.kubeconfig
kubectl config set-credentials "kubelet-bootstrap" \
  --token=ebe4f1e22044e23638394dd24d4aff49 \
  --kubeconfig=bootstrap.kubeconfig
kubectl config set-context default \
  --cluster=kubernetes \
  --user="kubelet-bootstrap" \
  --kubeconfig=bootstrap.kubeconfig
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig

cp bootstrap.kubeconfig /opt/kubernetes/cfg 
```

创建system服务管理文件。

```bash
cat > /usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kubelet.conf
ExecStart=/opt/kubernetes/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

启动

```bash
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
```

启动之后，在Master节点可以看到申请，需要执行如下命令来接受。

```bash 
# 查看node 加入申请
[root@10-11-master]# kubectl get csr
NAME                                                   AGE   REQUESTOR           CONDITION
node-csr-zXbvV_-slQhtuuKZddLIl9H4mKEfOhTkB-8TtaW2Nf8   36s   kubelet-bootstrap   Pending

# 接受申请
kubectl certificate approve node-csr-zXbvV_-slQhtuuKZddLIl9H4mKEfOhTkB-8TtaW2Nf8

# 查看node 
[root@10-11-master]# kubectl get node
NAME                     STATUS     ROLES    AGE    VERSION
75-33-65-shx-node        NotReady   <none>   1s     v1.16.0
```

> 节点状态为 NotReady，稍后等kubelet初始化好后，变为 Ready。有些kubelet配置了cni(容器网络接口)插件，当插件安装之前，不会变为Ready。

#### 3.2/ kube-proxy 部署

证书签发

```bash
cd /opt/kubernetes/ssl
cat > kube-proxy-csr.json << EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "BeiJing",
      "ST": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# 生成证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

ls kube-proxy*pem
kube-proxy-key.pem  kube-proxy.pem
```

环境变量配置文件

```
# 环境变量配置文件
cat > /opt/kubernetes/cfg/kube-proxy.conf << EOF
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=2 \\
--log-dir=/opt/kubernetes/logs \\
--config=/opt/kubernetes/cfg/kube-proxy-config.yml"
EOF

# 配置文件
cat > /opt/kubernetes/cfg/kube-proxy-config.yml << EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
metricsBindAddress: 0.0.0.0:10249
clientConnection:
  kubeconfig: /opt/kubernetes/cfg/kube-proxy.kubeconfig
hostnameOverride: 10-14-node
clusterCIDR: 10.10.0.0/16
EOF
```

systemd 服务管理脚本

```bash 
cat > /usr/lib/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=/opt/kubernetes/cfg/kube-proxy.conf
ExecStart=/opt/kubernetes/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

启动

```bash 
systemctl daemon-reload
systemctl start kube-proxy
systemctl enable kube-proxy
```

至此，Node 节点部署完成。其他Node 部署相同，修改对应ip和host即可。

### 4/ 网络插件部署

安装完Node节点组件之后，Pod内容器是可以通信的，但是Pod之间是无法通信的，这就需要CNI网络插件了。常用的CNI插件有Calico、flannel、Terway、Weave Net 以及 Contiv。这里选用常用的Flannel，如何选择CNI插件，大家可参考这篇文章 [理解 CNI 和 CNI 插件](https://www.kubernetes.org.cn/6908.html)。

CNI插件的安装方式有两种：

- ETCD 方式。这种方式就是利用etcd存储网络配置信息，并且利用dockerd启动参数`--bip`来指定每个节点的网段信息。
- CNI插件方式。这种方式是利用cni插件，并且将网络配置信息存储在kubernetes api中，Kubulet找到对应的cni插件，有插件分配节点IP网段。

CNI 插件主要部署在有Pod 调度的节点，常部署在Node节点。

#### 4.1/ CNI方式安装

CNI插件方式，首先需要在Master 各组件增加一些参数。

1/ 修改controller参数

在kube-controller-manager启动脚本中加入下边两个参数：

- `--allocate-node-cidrs=true` 节点允许自动分配网段。
- `--cluster-cidr=10.10.0.0/16` 为我们指定的集群的网段，这样每一个docker节点都会分别使用自网段10.10.0.0/24，10.10.1.0/24作为每个pod的网段，可以通过`kubectl get pod <pod_name> -o yaml`命令查看`spec.podCIDR`字段。

如果不配置该步骤可能会`flannel`出现`error registering network: failed to acquire lease: node "192.168.10.14" pod`的错误

2/ 修改kubelet参数

指定kubelet网络插件，在kubelet中指定如下三个参数：

- `--network-plugin=cni` 网络插件使用cni，必须添加，否则默认走docker自己的网络。
- `--cni-conf-dir=/etc/cni/net.d` cni配置文件 ，默认
- `--cni-bin-dir=/opt/cni/bin` cni可执行文件，默认
  
这样在kublet启动的时候，就会去/etc/cni/net.d目录查找配置文件，并解析，使用相应的插件配置网络

3/ 下载cni依赖插件

下载cni官方提供的组件：[cni-plugins-amd64-v0.7.1.tgz](https://github.com/containernetworking/plugins/releases/download/v0.7.1/cni-plugins-amd64-v0.7.1.tgz) ，并将可执行文件放在/opt/cni/bin目录。

这里不单单只会用到flannel文件，也会用到brage用来创建网桥以及host-local用来分配ip。

这一步不是必须的，当使用yum 安装 kubelet时，会自动下载依赖的`kubernetes-cni`包，并放置到相应位置。

4/ 安装flanneld组件

flannel组件直接以`daemonset`的方式安装在k8s集群中：

```
wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f kube-flannel.yml
```

其中`kube-flannel-cfg` configmap 中的 Network 字段需要与`--cluster-cidr`配置的网段一致。

这一步主要是安装了`flanneld`以及将`flannel`配置文件写入`/etc/cni/net.d`目录。

查看`kube-flannel.yml`中`flanneld`的启动参数为：

```bash
--ip-masq : 需要为其配置SNAT
--kube-subnet-mgr : 代表其使用kube类型的subnet-manager。该类型有别于使用etcd的local-subnet-mgr类型，使用kube类型后，flannel上各Node的IP子网分配均基于K8S Node的`spec.podCIDR`属性
```

#### 4.2/ ETCD 方式

ETCD 方式安装`Flannel`，参数无需修改，可保持之前步骤中的参数。

1/ 创建Flannel使用的网段

该方式，网段信息是保存在ETCD的，需要我们手动的添加

```bash
[root@10-14-node ~]# ETCDCTL_API=2 etcdctl --ca-file=/usr/local/kubernetes/etcd/ssl/ca.pem --cert-file=/usr/local/kubernetes/etcd/ssl/server.pem --key-file=/usr/local/kubernetes/etcd/ssl/server-key.pem --endpoints="https://192.168.10.14:2379,https://192.168.10.15:2379,https://192.168.10.16:2379" set /coreos.com/network/config '{"Network":"10.10.0.0/16","Backend":{"Type":"vxlan"}}'
{"Network":"10.10.0.0/16","Backend":{"Type":"vxlan"}}
[root@10-14-node ~]# ETCDCTL_API=2 etcdctl --ca-file=/usr/local/kubernetes/etcd/ssl/ca.pem --cert-file=/usr/local/kubernetes/etcd/ssl/server.pem --key-file=/usr/local/kubernetes/etcd/ssl/server-key.pem --endpoints=https://192.168.10.14:2379,https://192.168.10.15:2379,https://192.168.10.16:2379 get /coreos.com/network/config
{"Network":"10.10.0.0/16","Backend":{"Type":"vxlan"}}
[root@10-15-node ~]# ETCDCTL_API=2 etcdctl --ca-file=/usr/local/kubernetes/etcd/ssl/ca.pem --cert-file=/usr/local/kubernetes/etcd/ssl/server.pem --key-file=/usr/local/kubernetes/etcd/ssl/server-key.pem --endpoints=https://192.168.10.14:2379,https://192.168.10.15:2379,https://192.168.10.16:2379 get /coreos.com/network/config
{"Network":"10.10.0.0/16","Backend":{"Type":"vxlan"}}
```

> 使用该方式安装时，flannel仅支持etcd2版本的api，针对etcd 3+ 需要做下兼容。在etcd的启动时添加参数`--enable-v2` 做兼容。etcdctl 执行时，需要加 `ETRCDCTL_API=2` 的环境变量。
> 不做兼容的话，汇报如下错误：`Couldn't fetch network config: client: response is invalid json. The endpoint is probably not valid etcd cluster endpoint. timed out`, 可见这个[issue](https://github.com/coreos/flannel/issues/1191)。

2/ 安装Flannel 

下载二进制文件，https://github.com/coreos/flannel/releases , 这里选用 0.11。

```
wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz
tar zxvf flannel-v0.11.0-linux-amd64.tar.gz
mv flanneld mk-docker-opts.sh /opt/kubernetes/bin/

# 配置文件
cat > /opt/kubernetes/cfg/flannel.conf << EOF
FLANNEL_OPTIONS="--etcd-endpoints=https://192.168.10.14:2379,https://192.168.10.14:2379,https://192.168.10.14:2379 \\
--etcd-cafile=/opt/etcd/ssl/ca.pem \\
--etcd-certfile=/opt/etcd/ssl/server.pem \\
--etcd-keyfile=/opt/etcd/ssl/server-key.pem"
EOF

# 添加启动文件
cat > /usr/lib/systemd/system/flanneld.service << EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/usr/local/kubernetes/cfg/flannel.conf
ExecStart=/usr/local/kubernetes/bin/flanneld --ip-masq $FLANNEL_OPTIONS
ExecStartPost=/usr/local/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动 
systemctl daemon-reload 
systemctl start flanneld
systemctl enable flanneld
```

启动之后会在`/run/flannel/subnet.env` 生成一个子网描述文件，内容如下：

```bash
DOCKER_OPT_BIP="--bip=10.10.101.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=10.10.101.1/24 --ip-masq=false --mtu=1450"
```

我们需要将它配置为Docker 的环境变量，以供Docker 分配ip使用。

```bash
[Service]
...
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock $DOCKER_NETWORK_OPTIONS
...
```

重启Docker，以加载新的配置。

```
systemctl daemon-reload
systemctl restart docker
```

至此，Flannel 插件边安装完成了。安装完成后，可通过 `ip a `看到，自动创建了一个`flannel.1` 类似名称的虚拟网卡出现，主要用来做vxlan报文的处理，封包和解包。

```bash
[root@10-14-node ]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether c4:b8:b4:91:4e:99 brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.14/24 brd 192.168.10.255 scope global eth0
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether c4:b8:b4:91:4e:9a brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:26:57:30:53 brd ff:ff:ff:ff:ff:ff
    inet 10.10.101.1/24 brd 10.10.101.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:26ff:fe57:3053/64 scope link
       valid_lft forever preferred_lft forever
9: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    link/ether 2a:3c:d8:f4:f9:aa brd ff:ff:ff:ff:ff:ff
    inet 10.10.101.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::283c:d8ff:fef4:f9aa/64 scope link
       valid_lft forever preferred_lft forever
```

在看路由：

```
[root@75-33-65-shx-node data0]# route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         gateway         0.0.0.0         UG    0      0        0 eth0
10.10.15.0      10.10.15.0      255.255.255.0   UG    0      0        0 flannel.1
10.10.53.0      10.10.53.0      255.255.255.0   UG    0      0        0 flannel.1
10.10.66.0      10.10.66.0      255.255.255.0   UG    0      0        0 flannel.1
10.10.70.0      10.10.70.0      255.255.255.0   UG    0      0        0 flannel.1
10.10.96.0      10.10.96.0      255.255.255.0   UG    0      0        0 flannel.1
10.10.101.0     0.0.0.0         255.255.255.0   U     0      0        0 docker0
...
```
除了自身 `10.10.101.0`的包，其他`10.10.0.0/16 `网段的包都走 `flannel.1`虚拟网卡。


### 5/ DNS服务插件部署

在K8S中，DNS服务主要用来解析Service 名称和ip。当有新的service 时，无需知道它的ip直接使用名称即可调用。K8S 目标有两种常用的DNS方案，`kube-dns` 和`CoreDNS`。`CoreDNS`从1.11起，使用`kubeadm` 安装K8S时，是默认安装的。这里也选择安装 `CoreDNS`，因为`CoreDNS`服务是以pod的形式运行，所以下边操作只需在一台Master上操作即可。

下面开始安装：

```bash
# 下载 CoreDNS 项目
git clone https://github.com/coredns/deployment.git
cd coredns/deployment/kubernetes
```

找到 `deploy.sh`， 修改如下配置:

```bash 
111 if [[ -z $CLUSTER_DNS_IP ]]; then
112   # Default IP to kube-dns IP
113   # CLUSTER_DNS_IP=$(kubectl get service --namespace kube-system kube-dns -o jsonpath="{.spec.clusterIP}")
114   CLUSTER_DNS_IP=10.10.0.2
```

默认情况下 `CLUSTER_DNS_IP` 是自动获取`kube-dns`的集群ip的，但是由于没有部署kube-dns所以只能手动指定一个集群ip。

```bash 
# 生成 发布文件
sh deploy.sh > coredns.yaml

# 引用yaml 
kubectl apply -f coredns.yaml

kubectl get svc,pods -n kube-system| grep coredns
pod/coredns-759df9d7b-gzj5b   1/1     Running   0          22h

```

测试下：

```bash
cat > busybox.yml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: busybox:1.28.4
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF
kubectl apply -f busybox.yml
kubectl exec -i busybox nslookup kubernetes 
Server:    10.10.0.2
Address 1: 10.10.0.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.10.0.1 kubernetes.default.svc.cluster.local

```

出现以上信息，说明解析正常。

### 6/ Dashboard 部署

K8S 官方提供了一个web的操作界面叫Dashboard，可以满足基本的资源的创建、配置和修改。下面说下如何安装：

```bash 
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

# 下载好配置文件，修改service 访问策略为 NodePort，可直接通过node 的ip访问。
...
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001 # 新增
  type: NodePort   # 新增
...

kubectl apply -f recommended.yaml
kubectl get pods,svc -n kubernetes-dashboard
NAME                                             READY   STATUS    RESTARTS   AGE
pod/dashboard-metrics-scraper-76585494d8-hbjj4   1/1     Running   0          8d
pod/kubernetes-dashboard-5996555fd8-j5kq9        1/1     Running   0          8d

NAME                                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
service/dashboard-metrics-scraper   ClusterIP   10.10.130.25   <none>        8000/TCP        8d
service/kubernetes-dashboard        NodePort    10.10.32.39    <none>        443:30001/TCP   8d

```
可通过 `https://<node_ip>:30001` 来访问，系统提供了两种任务方式，我们常用token认证方式，下边我们来生成token。

```bash
# 创建service admin 账户 dashboard-admin 
kubectl create serviceaccount dashboard-admin -n kube-system
# 绑定集群默认管理员角色 cluster-admin 
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
# 查看登录 token 
kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}')
```
可使用上边输出的token ，登录dashboard。

### 高可用架构

到这里，我们所有节点组件完成。我们的架构如下图：

![](https://gitee.com/pylixm/picture/raw/master/2020-9-3/1599122141042-991704-20200721175907693-1828012284.png)

从图中我们可以看出一个问题，`controller-manager` 和`scheduler`可通过`etcd`间接的通信实现互为备份高可用，而`apiserver`则没有。架构中所有的Node都是连接的一台Master 的apiserver，其他两台并没有利用起来，连接的这台一旦出现故障，整个系统便无法使用。这个问题，常用的解决方案是使用 `nginx` 和 `keeplive` 实现，架构如下：

![](https://gitee.com/pylixm/picture/raw/master/2020-9-3/1599122144743-991704-20200721182337381-1239926526.png)

因为需要单独申请VIP，我并没有做具体搭建，仅使用nginx做了负载均衡。需要注意的是，这里Nginx 用来做四层的负载均衡使用 `stream`配置段，和`http`略有不同。

这里简单说下搭建步骤，最少使用两台机器互为主备。

```bash
# 安装nginx 和 keepalive。
yum install epel-release -y
yum install nginx keepalived -y

# nginx 配置文件
cat > /etc/nginx/nginx.conf << "EOF"
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

# 四层负载均衡，为两台Master apiserver组件提供负载均衡
stream {

    log_format  main  '$remote_addr $upstream_addr - [$time_local] $status $upstream_bytes_sent';

    access_log  /var/log/nginx/k8s-access.log  main;

    upstream k8s-apiserver {
       server 192.168.10.14:6443;   # Master1 APISERVER IP:PORT
       server 192.168.10.15:6443;   # Master2 APISERVER IP:PORT
       server 192.168.10.16:6443;   # Master2 APISERVER IP:PORT
    }
    
    server {
       listen 6443;
       proxy_pass k8s-apiserver;
    }
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    server {
        listen       80 default_server;
        server_name  _;

        location / {
        }
    }
}
EOF

# keepalive 主机配置文件
cat > /etc/keepalived/keepalived.conf << EOF
global_defs { 
   notification_email { 
     acassen@firewall.loc 
     failover@firewall.loc 
     sysadmin@firewall.loc 
   } 
   notification_email_from Alexandre.Cassen@firewall.loc  
   smtp_server 127.0.0.1 
   smtp_connect_timeout 30 
   router_id NGINX_MASTER
} 

vrrp_script check_nginx {
    script "/etc/keepalived/check_nginx.sh"
}

vrrp_instance VI_1 { 
    state MASTER 
    interface ens33
    virtual_router_id 51 # VRRP 路由 ID实例，每个实例是唯一的 
    priority 100    # 优先级，备服务器设置 90 
    advert_int 1    # 指定VRRP 心跳包通告间隔时间，默认1秒 
    authentication { 
        auth_type PASS      
        auth_pass 1111 
    }  
    # 虚拟IP
    virtual_ipaddress { 
        192.168.31.88/24
    } 
    track_script {
        check_nginx
    } 
}
EOF

# nginx 检测脚本，主备都需要有
cat > /etc/keepalived/check_nginx.sh  << "EOF"
#!/bin/bash
count=$(ps -ef |grep nginx |egrep -cv "grep|$$")

if [ "$count" -eq 0 ];then
    exit 1
else
    exit 0
fi
EOF
chmod +x /etc/keepalived/check_nginx.sh

# keepalive 备机配置文件
cat > /etc/keepalived/keepalived.conf << EOF
global_defs { 
   notification_email { 
     acassen@firewall.loc 
     failover@firewall.loc 
     sysadmin@firewall.loc 
   } 
   notification_email_from Alexandre.Cassen@firewall.loc  
   smtp_server 127.0.0.1 
   smtp_connect_timeout 30 
   router_id NGINX_BACKUP
} 

vrrp_script check_nginx {
    script "/etc/keepalived/check_nginx.sh"
}

vrrp_instance VI_1 { 
    state BACKUP 
    interface ens33
    virtual_router_id 51 # VRRP 路由 ID实例，每个实例是唯一的 
    priority 90
    advert_int 1
    authentication { 
        auth_type PASS      
        auth_pass 1111 
    }  
    virtual_ipaddress { 
        192.168.31.88/24
    } 
    track_script {
        check_nginx
    } 
}
EOF

# 启动，并设置开机启动
systemctl daemon-reload
systemctl start nginx
systemctl start keepalived
systemctl enable nginx
systemctl enable keepalived

# ip a ,可以看到 vip 已经绑定到网卡上 
inet 192.168.31.88/24 scope global secondary ens33
    valid_lft forever preferred_lft forever
```

接下里，将所有Node节点改为链接 VIP 的`apiserver`，重启 `kubelet` 和 `kube-proxy` 即可。

至此，一个高可用的K8S集群便搭建完成了，尽情享用吧。



## 扩展阅读

- [1/ 通过 Kubeadm 安装 K8S 与高可用](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/)
- [2/ Kubernetes中文文档](https://www.kubernetes.org.cn/docs)
- [3/ 详解 DNS 与 CoreDNS 的实现原理](https://draveness.me/dns-coredns/)
- [4/ Flannel网络](https://www.cnblogs.com/goldsunshine/p/10740928.html)