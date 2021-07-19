# ДЗ 32. DNS - настройка и обслуживание
настраиваем split-dns

взять стенд https://github.com/erlong15/vagrant-bind добавить еще один сервер client2 завести в зоне dns.lab имена web1 - смотрит на клиент1 web2 смотрит на клиент2

завести еще одну зону newdns.lab завести в ней запись www - смотрит на обоих клиентов

настроить split-dns клиент1 - видит обе зоны, но в зоне dns.lab только web1

клиент2 видит только dns.lab

*) настроить все без выключения selinux

---
Добавляем в `Vagrantfile` ещё одну `VM` *client2* (192.168.50.20).

Вносим изменения в стенд, согласно ДЗ.

### В `master-named.conf`: ###
*  добаявляем `ACL` и объявляем вид зоны для *client2*
```
...
acl "v1" { !192.168.50.20; any; };
acl "v2" { 192.168.50.20; };

view "zonev1" {
	match-clients { "v1"; };
	allow-transfer {192.168.50.11;};
        recursion yes;
...
```
* Добавляем и настраиваем зону `newdns.lab`
```
...
//newdns.lab
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.newdns.lab";
};
};

view "zonev2" {
	match-clients { "v2"; };
        allow-transfer { 192.168.50.11; };
        recursion yes;

// root zone
zone "." IN {
	type hint;
        file "named.ca";
};

// zones like localhost
include "/etc/named.rfc1912.zones";
// root's DNSKEY
include "/etc/named.root.key";

zone "dns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab";
};

// lab's zone reverse
zone "50.168.192.in-addr.arpa" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/etc/named/named.dns.lab.rev";
};
};
...
```
### В `slave-named.conf`: ###
* добаявляем `ACL` и объявляем вид зоны для *client2*
```
...
acl "v1" { !192.168.50.20; any; };
acl "v2" { 192.168.50.20; };

view "zonev1" {
	    match-clients { "v1"; };
        recursion yes;
...
```
* Добавляем и настраиваем зону `newdns.lab`
```
...
//newdns.lab
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.newdns.lab";
};
};
view "zonev2" {
	    match-clients { "v2"; };
        recursion yes;
// root zone
zone "." IN {
	type hint;
	file "named.ca";
};
// zones like localhost
include "/etc/named.rfc1912.zones";
// root's DNSKEY
include "/etc/named.root.key";
// lab's zone
zone "dns.lab" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.dns.lab";
};
// lab's zone reverse
zone "50.168.192.in-addr.arpa" {
    type slave;
    masters { 192.168.50.10; };
    file "/etc/named/named.dns.lab.rev";
};
};
...
```
### Настраиваем в Ansible playbook `selinux` и добавляем настройки для *client2* : ###
```
...
semanage fcontext -a -e /var/named /etc/named && restorecon -R -v /etc/named && setsebool -P named_write_master_zones 1
...
```
```
...
- hosts: client2
  sudo: yes
  become: yes
  tasks:

  - name: setup selinux
    shell: semanage fcontext -a -e /var/named /etc/named && restorecon -R -v /etc/named && setsebool -P named_write_master_zones 1

  - name: copy resolv.conf to the client2
    copy: src=client-resolv.conf dest=/etc/resolv.conf owner=root group=root mode=0644
  - name: copy rndc conf file
    copy: src=rndc.conf dest=/home/vagrant/rndc.conf owner=vagrant group=vagrant mode=0644
  - name: copy motd to the client2
    copy: src=client-motd dest=/etc/motd owner=root group=root mode=0644
...
```
### Создаём настройки прямой и обратной зоны для `newdns` в `named.newdns.lab` и `named.newdns.lab.rev` ###

----
## Проверяем. ##
*Client1* видит обе зоны, в зоне `dns.lab` - только `web1.dns.lab`
```
[vagrant@client ~]$nslookup web1.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web1.dns.lab
Address: 192.168.50.15

[vagrant@client ~]$ nslookup web2.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

** server can't find web2.dns.lab: NXDOMAIN

[vagrant@client ~]$ nslookup www.newdns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   www.newdns.lab
Address: 192.168.50.20
Name:   www.newdns.lab
Address: 192.168.50.15
```
*Client2* видит только `dns.lab`
```
[vagrant@client2 ~]$ nslookup web1.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web1.dns.lab
Address: 192.168.50.15

[vagrant@client2 ~]$ nslookup web2.dns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

Name:   web2.dns.lab
Address: 192.168.50.20

[vagrant@client2 ~]$ nslookup www.newdns.lab
Server:         192.168.50.10
Address:        192.168.50.10#53

** server can't find www.newdns.lab: NXDOMAIN
```
