# ДЗ 21. Сбор и анализ логов
Настраиваем центральный сервер для сбора логов

в вагранте поднимаем 2 машины web и log на web поднимаем nginx на log настраиваем центральный лог сервер на любой системе на выбор

* journald
* rsyslog
* elk настраиваем аудит следящий за изменением конфигов нжинкса

все критичные логи с web должны собираться и локально и удаленно все логи с nginx должны уходить на удаленный сервер (локально только критичные) логи аудита должны также уходить на удаленную систему

** развернуть еще машину elk и таким образом настроить 2 центральных лог системы elk И какую либо еще в elk должны уходить только логи нжинкса во вторую систему все остальное

----
`Vagrantfile` поднимает две машины: **`web`** и **`log`** и проводит следующие манипуляции.

На машине **`web`** устанавливаются и запускаются `nginx` и `rsyslog`.
Устанавливается `audispd-plugins` для удалённой отправки аудируемых событий.
Настраиваем правило `auditctl` для `nginx`:
```
sudo auditctl -w /etc/nginx/ -k nginx_watch
sudo auditctl -l >> /etc/audit/rules.d/nginx.rules
```
Правим конфигурацию `nginx`:
```
...
error_log syslog:server=192.168.11.151:514;
error_log /var/log/nginx/error.log;
...
access_log syslog:server=192.168.11.151:514 main;
...
```
Правим конфигурацию для отправки в `rsyslog` на машину **`log`** сообщений категорий: `*.err`, `*.alert`, `*.crit`, `*.warning` и `*.notice`.
Правим конфигурацию `audisp` в `/etc/audisp/plugins.d/au-remote.conf`:
```
active = yes
direction = out
path = /sbin/audisp-remote
type = always
#args =
format = string
```
Указываем удалённый сервер в `/etc/audisp/audisp-remote.conf`
```
...
remote_server = 192.168.11.151
...
```
Перезапускаем службу `auditd`, `rsyslog` и `nginx`.

На машине **`log`** устанавливается и запускается `rsyslog`.
Прописываем в конфигурации `/etc/audit/auditd.conf` порт, который слушать.
```
...
tcp_listen_port = 60
...
```
В конфигурации `/etc/rsyslog.conf` разкомментируем:
```
...
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514
...
```
и укажем куда складываем логи с удалённого хоста:
```
...
$template RemoteLogs,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
...
```
Перезапускаем службу auditd и rsyslog.

Проверяем, что на машину **`log`** в `/var/log/web` складываются все логи с **`web`** по `nginx`, критичные логи и аудита:
```
[root@log web]# tail -f nginx.log
Apr 22 08:37:37 web nginx: 192.168.11.151 - - [22/Apr/2021:08:37:37 +0000] "GET / HTTP/1.1" 200 4833 "-" "curl/7.29.0" "-"
Apr 22 08:37:41 web nginx: 2021/04/22 08:37:41 [error] 5629#0: *10 open() "/usr/share/nginx/html/asd" failed (2: No such file or directory), client: 192.168.11.151, server: _, request: "GET /asd HTTP/1.1", host: "192.168.11.150"
Apr 22 08:37:41 web nginx: 192.168.11.151 - - [22/Apr/2021:08:37:41 +0000] "GET /asd HTTP/1.1" 404 3650 "-" "curl/7.29.0" "-"
Apr 22 09:06:49 web nginx: 192.168.11.151 - - [22/Apr/2021:09:06:49 +0000] "GET / HTTP/1.1" 200 4833 "-" "curl/7.29.0" "-"
Apr 22 09:06:56 web nginx: 2021/04/22 09:06:56 [error] 5629#0: *14 open() "/usr/share/nginx/html/aswe" failed (2: No such file or directory), client: 192.168.11.151, server: _, request: "GET /aswe HTTP/1.1", host: "192.168.11.150"
Apr 22 09:06:56 web nginx: 192.168.11.151 - - [22/Apr/2021:09:06:56 +0000] "GET /aswe HTTP/1.1" 404 3650 "-" "curl/7.29.0" "-"
Apr 22 09:22:10 web nginx: 2021/04/22 09:22:10 [error] 5629#0: *19 open() "/usr/share/nginx/html/ddd" failed (2: No such file or directory), client: 192.168.11.151, server: _, request: "GET /ddd HTTP/1.1", host: "192.168.11.150"
Apr 22 09:22:10 web nginx: 192.168.11.151 - - [22/Apr/2021:09:22:10 +0000] "GET /ddd HTTP/1.1" 404 3650 "-" "curl/7.29.0" "-"
Apr 22 09:22:30 web nginx: 2021/04/22 09:22:30 [error] 5629#0: *20 open() "/usr/share/nginx/html/ddds" failed (2: No such file or directory), client: 192.168.11.151, server: _, request: "GET /ddds HTTP/1.1", host: "192.168.11.150"
Apr 22 09:22:30 web nginx: 192.168.11.151 - - [22/Apr/2021:09:22:30 +0000] "GET /ddds HTTP/1.1" 404 3650 "-" "curl/7.29.0" "-"
```

```
[root@log web]# tail -f sudo.log
Apr 22 08:32:22 web sudo: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/cat /var/log/nginx/error.log
Apr 22 08:32:29 web sudo: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/cat /var/log/nginx/acceas.log
Apr 22 08:32:34 web sudo: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/cat /var/log/nginx/access.log
Apr 22 08:35:05 web sudo: vagrant : TTY=pts/0 ; PWD=/home/vagrant ; USER=root ; COMMAND=/bin/cd /var/log/nginx/
Apr 22 09:10:58 web sudo: vagrant : TTY=pts/0 ; PWD=/var/log ; USER=root ; COMMAND=/bin/yum install mc -y

```