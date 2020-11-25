---
type : posts
title : 记一次 Linux OOM-killer 分析过程
categories: [Linux,] 
date : 2018-11-28
url: /posts/2018-11-28-Linux-oom-killer.html 
tags : [Linux, 运维知识库]
---


## 问题现象

最近发现线上服务的服务节点经常性的挂掉，我们业务的线上服务使用docker跑的Tomcat服务。服务业务现象收集如下：

- tomcat的相关日志，并没有明显的报错信息，但是所有日志均停在了同一时刻。
- docker容器是活着的，但是Java进程挂了。
- 重新启动服务后，内存占用比较高。服务器内存配置16G，jvm Xmx8g Xmn4g。
- 磁盘IO比较高。

作为运维，服务有没有内存溢出等问题暂且放一边，先从服务器这边排查下问题。首先怀疑是资源占用比较高，系统把服务干掉了。查看系统日志 message 发现如下日志，证实了猜想：

```
Nov 27 21:02:21 localhost kernel: java invoked oom-killer: gfp_mask=0x280da, order=0, oom_score_adj=0
Nov 27 21:02:21 localhost kernel: java cpuset=aa5075722ccf791119d698c46ae14d51d2d2d45d479eee43fda347b6df0f5773 mems_allowed=0-1
Nov 27 21:02:21 localhost kernel: CPU: 15 PID: 42005 Comm: java Tainted: G            -------------- T 3.10.0-229.el7.x86_64 #1
Nov 27 21:02:21 localhost kernel: Hardware name: Huawei RH1288A V2/BC11SRSK0, BIOS RMIBV512 08/27/2015
Nov 27 21:02:21 localhost kernel: ffff880287fee660 000000005270c3fe ffff880471377a58 ffffffff81604b0a
Nov 27 21:02:21 localhost kernel: ffff880471377ae8 ffffffff815ffaaf ffff8803428abf30 ffff8803428abf48
Nov 27 21:02:21 localhost kernel: 0000000000000206 ffff880287fee660 ffff880471377ad0 ffffffff81117aef
Nov 27 21:02:21 localhost kernel: Call Trace:
Nov 27 21:02:21 localhost kernel: [<ffffffff81604b0a>] dump_stack+0x19/0x1b
Nov 27 21:02:21 localhost kernel: [<ffffffff815ffaaf>] dump_header+0x8e/0x214
Nov 27 21:02:21 localhost kernel: [<ffffffff81117aef>] ? delayacct_end+0x8f/0xb0
Nov 27 21:02:21 localhost kernel: [<ffffffff8115a44e>] oom_kill_process+0x24e/0x3b0
Nov 27 21:02:21 localhost kernel: [<ffffffff81159fb6>] ? find_lock_task_mm+0x56/0xc0
Nov 27 21:02:21 localhost kernel: [<ffffffff8115ac76>] out_of_memory+0x4b6/0x4f0
Nov 27 21:02:21 localhost kernel: [<ffffffff81160e55>] __alloc_pages_nodemask+0xa95/0xb90
Nov 27 21:02:21 localhost kernel: [<ffffffff811a29da>] alloc_pages_vma+0x9a/0x140
Nov 27 21:02:21 localhost kernel: [<ffffffff81182fb7>] handle_mm_fault+0x9f7/0xd70
Nov 27 21:02:21 localhost kernel: [<ffffffff810a94f6>] ? try_to_wake_up+0x1b6/0x280
Nov 27 21:02:21 localhost kernel: [<ffffffff810a95e3>] ? wake_up_process+0x23/0x40
Nov 27 21:02:21 localhost kernel: [<ffffffff8160fe06>] __do_page_fault+0x156/0x540
Nov 27 21:02:21 localhost kernel: [<ffffffff812e3247>] ? call_rwsem_wake+0x17/0x30
Nov 27 21:02:21 localhost kernel: [<ffffffff8109c42d>] ? up_write+0x1d/0x20
Nov 27 21:02:21 localhost kernel: [<ffffffff810faec6>] ? __audit_syscall_exit+0x1f6/0x2a0
Nov 27 21:02:21 localhost kernel: [<ffffffff8161020a>] do_page_fault+0x1a/0x70
Nov 27 21:02:21 localhost kernel: [<ffffffff8160c408>] page_fault+0x28/0x30
Nov 27 21:02:21 localhost kernel: Mem-Info:
Nov 27 21:02:21 localhost kernel: Node 0 DMA per-cpu:
Nov 27 21:02:21 localhost kernel: CPU    0: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    1: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    2: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    3: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    4: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    5: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    6: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    7: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    8: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    9: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   10: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   11: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   12: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   13: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   14: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   15: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   16: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   17: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   18: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   19: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   20: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   21: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   22: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   23: hi:    0, btch:   1 usd:   0
Nov 27 21:02:21 localhost kernel: Node 0 DMA32 per-cpu:
Nov 27 21:02:21 localhost kernel: CPU    0: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    1: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    2: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    3: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    4: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    5: hi:  186, btch:  31 usd:   2
Nov 27 21:02:21 localhost kernel: CPU    6: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    7: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    8: hi:  186, btch:  31 usd:   3
Nov 27 21:02:21 localhost kernel: CPU    9: hi:  186, btch:  31 usd:   1
Nov 27 21:02:21 localhost kernel: CPU   10: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   11: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   12: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   13: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   14: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   15: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   16: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   17: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   18: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   19: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   20: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   21: hi:  186, btch:  31 usd:  12
Nov 27 21:02:21 localhost kernel: CPU   22: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   23: hi:  186, btch:  31 usd:  15
Nov 27 21:02:21 localhost kernel: Node 0 Normal per-cpu:
Nov 27 21:02:21 localhost kernel: CPU    0: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    1: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    2: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    3: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    4: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    5: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    6: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    7: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    8: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    9: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   10: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   11: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   12: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   13: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   14: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   15: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   16: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   17: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   18: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   19: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   20: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   21: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   22: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   23: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: Node 1 Normal per-cpu:
Nov 27 21:02:21 localhost kernel: CPU    0: hi:  186, btch:  31 usd:  46
Nov 27 21:02:21 localhost kernel: CPU    1: hi:  186, btch:  31 usd:   2
Nov 27 21:02:21 localhost kernel: CPU    2: hi:  186, btch:  31 usd:  42
Nov 27 21:02:21 localhost kernel: CPU    3: hi:  186, btch:  31 usd:   2
Nov 27 21:02:21 localhost kernel: CPU    4: hi:  186, btch:  31 usd:  31
Nov 27 21:02:21 localhost kernel: CPU    5: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU    6: hi:  186, btch:  31 usd:  16
Nov 27 21:02:21 localhost kernel: CPU    7: hi:  186, btch:  31 usd: 164
Nov 27 21:02:21 localhost kernel: CPU    8: hi:  186, btch:  31 usd:  19
Nov 27 21:02:21 localhost kernel: CPU    9: hi:  186, btch:  31 usd:  18
Nov 27 21:02:21 localhost kernel: CPU   10: hi:  186, btch:  31 usd:   8
Nov 27 21:02:21 localhost kernel: CPU   11: hi:  186, btch:  31 usd:  20
Nov 27 21:02:21 localhost kernel: CPU   12: hi:  186, btch:  31 usd:  31
Nov 27 21:02:21 localhost kernel: CPU   13: hi:  186, btch:  31 usd:  27
Nov 27 21:02:21 localhost kernel: CPU   14: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   15: hi:  186, btch:  31 usd:   4
Nov 27 21:02:21 localhost kernel: CPU   16: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   17: hi:  186, btch:  31 usd:  30
Nov 27 21:02:21 localhost kernel: CPU   18: hi:  186, btch:  31 usd:  30
Nov 27 21:02:21 localhost kernel: CPU   19: hi:  186, btch:  31 usd:   0
Nov 27 21:02:21 localhost kernel: CPU   20: hi:  186, btch:  31 usd:   3
Nov 27 21:02:21 localhost kernel: CPU   21: hi:  186, btch:  31 usd:  24
Nov 27 21:02:21 localhost kernel: CPU   22: hi:  186, btch:  31 usd:  12
Nov 27 21:02:21 localhost kernel: CPU   23: hi:  186, btch:  31 usd:  18
Nov 27 21:02:21 localhost kernel: active_anon:2724567 inactive_anon:177005 isolated_anon:0
Nov 27 21:02:21 localhost kernel: Node 0 DMA free:15900kB min:88kB low:108kB high:132kB active_anon:0kB inactive_anon:0kB active_file:0kB inactive_file:0kB unevictable:0kB isolated(anon):0kB isolated(file):0kB present:15984kB managed:15900kB mlocked:0kB dirty:0kB writeback:0kB mapped:0kB shmem:0kB slab_reclaimable:0kB slab_unreclaimable:0kB kernel_stack:0kB pagetables:0kB unstable:0kB bounce:0kB free_cma:0kB writeback_tmp:0kB pages_scanned:0 all_unreclaimable? yes
Nov 27 21:02:21 localhost kernel: lowmem_reserve[]: 0 1764 7766 7766
Nov 27 21:02:21 localhost kernel: Node 0 DMA32 free:34556kB min:10040kB low:12548kB high:15060kB active_anon:1612600kB inactive_anon:65356kB active_file:0kB inactive_file:0kB unevictable:0kB isolated(anon):0kB isolated(file):0kB present:2052096kB managed:1808016kB mlocked:0kB dirty:0kB writeback:0kB mapped:2344kB shmem:72780kB slab_reclaimable:39568kB slab_unreclaimable:23940kB kernel_stack:8096kB pagetables:5680kB unstable:0kB bounce:0kB free_cma:0kB writeback_tmp:0kB pages_scanned:184 all_unreclaimable? yes
Nov 27 21:02:21 localhost kernel: lowmem_reserve[]: 0 0 6002 6002
Nov 27 21:02:21 localhost kernel: Node 0 Normal free:33824kB min:34160kB low:42700kB high:51240kB active_anon:5423868kB inactive_anon:20808kB active_file:20kB inactive_file:12kB unevictable:0kB isolated(anon):0kB isolated(file):0kB present:6291456kB managed:6146484kB mlocked:0kB dirty:0kB writeback:0kB mapped:5364kB shmem:18288kB slab_reclaimable:108572kB slab_unreclaimable:85084kB kernel_stack:26192kB pagetables:14532kB unstable:0kB bounce:0kB free_cma:0kB writeback_tmp:0kB pages_scanned:114 all_unreclaimable? yes
Nov 27 21:02:21 localhost kernel: lowmem_reserve[]: 0 0 0 0
Nov 27 21:02:21 localhost kernel: Node 1 Normal free:46612kB min:45816kB low:57268kB high:68724kB active_anon:3861800kB inactive_anon:621856kB active_file:340kB inactive_file:40kB unevictable:0kB isolated(anon):0kB isolated(file):0kB present:8388608kB managed:8243396kB mlocked:0kB dirty:0kB writeback:132kB mapped:3756kB shmem:993724kB slab_reclaimable:120776kB slab_unreclaimable:139408kB kernel_stack:26976kB pagetables:18120kB unstable:0kB bounce:0kB free_cma:0kB writeback_tmp:0kB pages_scanned:2643 all_unreclaimable? yes
Nov 27 21:02:21 localhost kernel: lowmem_reserve[]: 0 0 0 0
Nov 27 21:02:21 localhost kernel: Node 0 DMA: 1*4kB (U) 1*8kB (U) 1*16kB (U) 0*32kB 2*64kB (U) 1*128kB (U) 1*256kB (U) 0*512kB 1*1024kB (U) 1*2048kB (R) 3*4096kB (M) = 15900kB
Nov 27 21:02:21 localhost kernel: Node 0 DMA32: 742*4kB (UEMR) 396*8kB (UEM) 344*16kB (UEM) 407*32kB (UEMR) 151*64kB (UEMR) 5*128kB (UMR) 0*256kB 1*512kB (R) 0*1024kB 0*2048kB 0*4096kB = 35480kB
Nov 27 21:02:21 localhost kernel: Node 0 Normal: 1015*4kB (UEMR) 599*8kB (UEM) 586*16kB (UEM) 376*32kB (UEM) 99*64kB (UEM) 1*128kB (M) 0*256kB 0*512kB 0*1024kB 0*2048kB 0*4096kB = 36724kB
Nov 27 21:02:21 localhost kernel: Node 1 Normal: 2725*4kB (UEMR) 1187*8kB (UEM) 460*16kB (UEM) 339*32kB (UEM) 106*64kB (UEM) 7*128kB (UM) 0*256kB 0*512kB 0*1024kB 0*2048kB 0*4096kB = 46284kB
Nov 27 21:02:21 localhost kernel: Node 0 hugepages_total=0 hugepages_free=0 hugepages_surp=0 hugepages_size=2048kB
Nov 27 21:02:21 localhost kernel: Node 1 hugepages_total=0 hugepages_free=0 hugepages_surp=0 hugepages_size=2048kB
Nov 27 21:02:21 localhost kernel: 272043 total pagecache pages
Nov 27 21:02:21 localhost kernel: 0 pages in swap cache
Nov 27 21:02:21 localhost kernel: Swap cache stats: add 17671445, delete 17671445, find 29162461/30280216
Nov 27 21:02:21 localhost kernel: Free swap  = 0kB
Nov 27 21:02:21 localhost kernel: Total swap = 0kB
Nov 27 21:02:21 localhost kernel: 4187036 pages RAM
Nov 27 21:02:21 localhost kernel: 0 pages HighMem/MovableOnly
Nov 27 21:02:21 localhost kernel: 133587 pages reserved
Nov 27 21:02:21 localhost kernel: [ pid ]   uid  tgid total_vm      rss nr_ptes swapents oom_score_adj name
Nov 27 21:02:21 localhost kernel: [ 1183]     0  1183    14046     2536      29        0             0 systemd-journal
Nov 27 21:02:21 localhost kernel: [ 1194]     0  1194    28172       64      21        0             0 lvmetad
Nov 27 21:02:21 localhost kernel: [ 1249]     0  1249    10682      189      22        0         -1000 systemd-udevd
Nov 27 21:02:21 localhost kernel: [ 2094]     0  2094    29177      123      25        0         -1000 auditd
Nov 27 21:02:21 localhost kernel: [ 2121]   997  2121     1084       30       7        0             0 lsmd
Nov 27 21:02:21 localhost kernel: [ 2124]     0  2124    53614      445      59        0             0 abrtd
Nov 27 21:02:21 localhost kernel: [ 2126]     0  2126    32512      129      21        0             0 smartd
Nov 27 21:02:21 localhost kernel: [ 2127]     0  2127   185139     2193     132        0             0 rsyslogd
Nov 27 21:02:21 localhost kernel: [ 2129]     0  2129    52996      340      56        0             0 abrt-watch-log
Nov 27 21:02:21 localhost kernel: [ 2130]     0  2130     4817       90      14        0             0 irqbalance
Nov 27 21:02:21 localhost kernel: [ 2131]     0  2131     1093       40       8        0             0 rngd
Nov 27 21:02:21 localhost kernel: [ 2132]     0  2132     8737      163      21        0             0 systemd-logind
Nov 27 21:02:21 localhost kernel: [ 2133]    81  2133     7224      180      20        0          -900 dbus-daemon
Nov 27 21:02:21 localhost kernel: [ 2534]     0  2534     6483       51      16        0             0 atd
Nov 27 21:02:21 localhost kernel: [ 2536]     0  2536     6794       59      18        0             0 xinetd
Nov 27 21:02:21 localhost kernel: [ 3458]     0  3458     9840      126      22        0         -1000 sshd
Nov 27 21:02:21 localhost kernel: [18475]     0 18475    27501       32      10        0             0 agetty
Nov 27 21:02:21 localhost kernel: [226241]   999 226241   129017     2131      48        0             0 polkitd
Nov 27 21:02:21 localhost kernel: [226841]    38 226841     8371      130      20        0             0 ntpd
Nov 27 21:02:21 localhost kernel: [17993]     0 17993     2838       50      11        0             0 init.sh
Nov 27 21:02:21 localhost kernel: [18033]     0 18033   271311     4160      94        0             0 python2.6
Nov 27 21:02:21 localhost kernel: [18034]     0 18034    11302     6761      28        0             0 python2.6
Nov 27 21:02:21 localhost kernel: [18042]     0 18042     1038       23       8        0             0 tail
Nov 27 21:02:21 localhost kernel: [133984]     0 133984  1556394     7033     190        0             0 scribed
Nov 27 21:02:21 localhost kernel: [41077]    99 41077     3880       48      12        0             0 dnsmasq
Nov 27 21:02:21 localhost kernel: [136214]     0 136214    27931      275      53        0             0 lldpd
Nov 27 21:02:21 localhost kernel: [136217]   990 136217    27931      260      52        0             0 lldpd
Nov 27 21:02:21 localhost kernel: [179346] 60422 179346    81770     2557      38        0             0 wagent
Nov 27 21:02:21 localhost kernel: [184527]     0 184527    52460     2085      57        0             0 python
Nov 27 21:02:21 localhost kernel: [184648]     0 184648    49745     1409      53        0             0 python
Nov 27 21:02:21 localhost kernel: [184670]     0 184670    47515     1281      49        0             0 python
Nov 27 21:02:21 localhost kernel: [184696]     0 184696    47514     1278      51        0             0 python
Nov 27 21:02:21 localhost kernel: [184718]     0 184718    47514     1283      48        0             0 python
Nov 27 21:02:21 localhost kernel: [184740]     0 184740    47514     1314      50        0             0 python
Nov 27 21:02:21 localhost kernel: [184762]     0 184762    47514     1302      51        0             0 python
Nov 27 21:02:21 localhost kernel: [56906]     0 56906   505000     6523     101        0             0 xxxAgent
Nov 27 21:02:21 localhost kernel: [38493]     0 38493   347897     6702      90        0          -500 dockerd
Nov 27 21:02:21 localhost kernel: [38776]     0 38776    31576      157      18        0             0 crond
Nov 27 21:02:21 localhost kernel: [39783]     0 39783   118293      662      24        0          -500 docker-containe
Nov 27 21:02:21 localhost kernel: [39805]     0 39805     3761       55      12        0             0 docker.sh
Nov 27 21:02:21 localhost kernel: [39855]     0 39855  6841020  2555504    7788        0             0 java
Nov 27 21:02:21 localhost kernel: [48691]     0 48691    48225     1480      52        0             0 python
Nov 27 21:02:21 localhost kernel: [90430]     0 90430   312213     1081      61        0          -500 docker-containe
Nov 27 21:02:21 localhost kernel: [68926]     0 68926     5624       62      16        0             0 xxagent
Nov 27 21:02:21 localhost kernel: [68932]     0 68932    12834     7251      30        0             0 xxagent
Nov 27 21:02:21 localhost kernel: [70100]     0 70100    42611      220      39        0             0 crond
Nov 27 21:02:21 localhost kernel: [70103]     0 70103    42611      220      39        0             0 crond
Nov 27 21:02:21 localhost kernel: [70176]     0 70176    28279       43      15        0             0 sh
Nov 27 21:02:21 localhost kernel: [70177]     0 70177    28279       42      13        0             0 sh
Nov 27 21:02:21 localhost kernel: [70182]     0 70182    28279       64      13        0             0 bash
Nov 27 21:02:21 localhost kernel: [70186]     0 70186    28279       43      12        0             0 bash
Nov 27 21:02:21 localhost kernel: [70205]     0 70205    32413       93      21        0             0 perl
Nov 27 21:02:21 localhost kernel: [70357]     0 70357    28279       63      11        0             0 bash
Nov 27 21:02:21 localhost kernel: [70718]     0 70718     1143       81       7        0             0 gzip
Nov 27 21:02:21 localhost kernel: Out of memory: Kill process 39855 (java) score 632 or sacrifice child
Nov 27 21:02:21 localhost kernel: Killed process 39855 (java) total-vm:27364080kB, anon-rss:10222016kB, file-rss:0kB
```

该日志可以说明 Java进程是被系统kill的了。下面我们来具体看下是怎么回事？

## 分析

Linux 系统有一种自我保护的机制叫做 OOM-killer，即当物理内存被进程使用完后，当再有进程来请求内存时，它就会把当前进程中最占用内存最多，回收内存收益最大的进程给kill掉来回收内存，保证系统的正常运行。

从上边的日志可以看到如下几行：

```
Nov 27 21:02:21 localhost kernel: Out of memory: Kill process 39855 (java) score 632 or sacrifice child
Nov 27 21:02:21 localhost kernel: Killed process 39855 (java) total-vm:27364080kB, anon-rss:10222016kB, file-rss:0kB
```

从这个日志中，我们可以看到 java进程 39855 因为Out of memory 被系统kill了。下边一行展示了当时他的内存占用情况，虚拟内存 27G左右，anon-rss(虚拟内存页，大家可理解为内存单元，每个大小为4k，一般为进程占用)10G左右,file-rss(文件内存也，当打开大文件时占用)0。

来看上边各进程内存占用情况，找到java 进程 rss 2555504*4k=10G 左右，此进程占用内存最大。其次有5个在6000+， 5*6000*4k=1.2G, 剩余进程大约在3~4g，正好为系统的16G。

当没有空余的内存时，触发OOM-killer机制，java进程占用内存最大，就被系统kill了。由于Java进程非正常退出，docker容器没有退出，但是已经不再提供服务了。

## 优化方案

**方案一，降低Java虚拟机配置的最大内存或增加机器物理内存**

在不影响服务的情况下，降低Java虚拟机配置的最大内存，从而降低整体内存的占用情况，虽然内存占用可能依然较高，但是整体会有所下降，触发OOM-killer机制的几率会减少。


**方案二，修改进程得分或关闭OOM-killer机制**

系统在选择进程来kill的时候，会根据某种算法计算出一个介于[-17,15]之间的数值，保存在 /proc/[pid]/oom_adj中，得分越高表示选中的可能性越大。-17表示禁止kill。我们可以修改这个得分来设置我们的进程不被kill。

```
$ echo -17 > /proc/$(pidof java)/oom_adj
```
也可采用禁止OOM-killer机制的方法。达到禁止kill的目的。如下：

```
# sysctl -w vm.overcommit_memory=2
```

此方案，可能会因进程占用大量内存而没有被释放，导致系统卡死，其他操作无法处理，生产环境不建议使用。

总之，预估好服务峰值时消耗的内存和机器的物理内存之间的关系是关键。


## 参考 

- [与Linux OOM-killer的第一次亲密接触](http://jm.taobao.org/2012/06/26/linux-oom-killer-first-touch/)
- [https://my.oschina.net/u/1998527/blog/903622](https://my.oschina.net/u/1998527/blog/903622)
- [https://blog.csdn.net/gugemichael/article/details/24017515](https://blog.csdn.net/gugemichael/article/details/24017515)
- [http://www.cnblogs.com/GoodGoodWorkDayDayUp/p/3473348.html](http://www.cnblogs.com/GoodGoodWorkDayDayUp/p/3473348.html)