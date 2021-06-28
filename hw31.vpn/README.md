# ДЗ 31. Мосты, туннели и VPN
VPN

* Между двумя виртуалками поднять vpn в режимах

*    tun
*   tap Прочуствовать разницу.

*   Поднять RAS на базе OpenVPN с клиентскими сертификатами, подключиться с локальной машины на виртуалку

3*. Самостоятельно изучить, поднять ocserv и подключиться с хоста к виртуалке

----
`Vagrantfile` поднимает две виртуальные машины (*server*, *client*) и с помошью `Ansible` устанавливает и настраивает на серверную и клиентскую часть `OpenVPN`, обновляет `epel`, отключает `SELinux` и открывает порт 5201 в `firewalld`. Ключ, сгенерированный на *server* копируется на *client*. Получается следующая схема:

![31vpn1](31vpn1.png)

### Проверяем, что VPN работает через tap:
```
4: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/ether 66:61:f5:0d:e5:61 brd ff:ff:ff:ff:ff:ff
    inet 10.1.1.1/24 brd 10.1.1.255 scope global tap0
       valid_lft forever preferred_lft forever
    inet6 fe80::6461:f5ff:fe0d:e561/64 scope link
       valid_lft forever preferred_lft forever
```
Запускаем `iperf3` на *server*:
```
[vagrant@server ~]$ iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------

```
Проверяем прохождение трафика с *client*:
```
[vagrant@client ~]$ iperf3 -c 10.1.1.1 -t 100 -i 10
Connecting to host 10.1.1.1, port 5201
[  4] local 10.1.1.2 port 58958 connected to 10.1.1.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-10.00  sec  14.2 MBytes  11.9 Mbits/sec    0    602 KBytes
[  4]  10.00-20.00  sec  13.9 MBytes  11.6 Mbits/sec  166   1.22 MBytes
[  4]  20.00-30.00  sec  12.5 MBytes  10.5 Mbits/sec   50   1.11 MBytes
[  4]  30.00-40.00  sec  12.3 MBytes  10.4 Mbits/sec   52    939 KBytes
[  4]  40.00-50.00  sec  13.6 MBytes  11.4 Mbits/sec   23    982 KBytes
[  4]  50.00-60.00  sec  12.3 MBytes  10.4 Mbits/sec    0   1.11 MBytes
[  4]  60.00-70.00  sec  13.6 MBytes  11.4 Mbits/sec   52   1.20 MBytes
[  4]  70.00-80.00  sec  12.4 MBytes  10.4 Mbits/sec   24   1.08 MBytes
[  4]  80.00-90.00  sec  12.3 MBytes  10.4 Mbits/sec   14   1.21 MBytes
[  4]  90.00-100.00 sec  13.6 MBytes  11.4 Mbits/sec   69    934 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-100.00 sec   131 MBytes  11.0 Mbits/sec  450             sender
[  4]   0.00-100.00 sec   128 MBytes  10.8 Mbits/sec                  receiver

iperf Done.
```
Для смены режима запускаем плейбук `ansible-playbook playbook2.yml`
