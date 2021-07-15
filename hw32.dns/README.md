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
* Добавляем зону `newdns.lab` и заводим в ней запись www, которая смотрит на обоих клиентов
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
### В `named.ddns.lab` и `named.dns.lab` добавляем `DNS Servers` `web1` и `web2` ###
```
...
web1		    IN	    A	    192.168.50.15
web2		    IN	    A	    192.168.50.20
...
```
### В `named.dns.lab.rev` добавляем PTR для `web1` и `web2` ###
```
...
15		        IN	    PTR	    web1.dns.lab.
20		        IN	    PTR	    web2.dns.lab.
...
```
