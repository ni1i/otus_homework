# ДЗ 17. SELinux - когда все запрещено
Тренируем умение работать с SELinux: диагностировать проблемы и модифицировать политики SELinux для корректной работы приложений, если это требуется.

1. Запустить nginx на нестандартном порту 3-мя разными способами:
    * переключатели setsebool;
    * добавление нестандартного порта в имеющийся тип;
    * формирование и установка модуля SELinux.
2. Обеспечить работоспособность приложения при включенном selinux.

    Развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems

    Выяснить причину неработоспособности механизма обновления зоны (см. README);

    Предложить решение (или решения) для данной проблемы;

    Выбрать одно из решений для реализации, предварительно обосновав выбор;

    Реализовать выбранное решение и продемонстрировать его работоспособность.
 ---
## Выполнение ДЗ:

## Задание 1. Запустить `nginx` на нестандартном порту 3-мя разными способами: 
    
##   1.1 переключатели `setsebool` 

   Устанавливаем `nginx` и пакет в который в ходит утилита `audit2why` (policycoreutils-python).
 
   Меняем порт *80* на *32123* в `/etc/nginx/nginx.conf`
```
server {
        listen       32123 default_server;
        listen       [::]:32123 default_server;
```
Запускаем nginx и видим ошибку:
```
[root@selinux vagrant]# systemctl start nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```
Смотрим что нам про это говорит `audit.log` через `audit2why`:
```
[root@selinux vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1617374099.354:1356): avc:  denied  { name_bind } for  pid=3420 comm="nginx" src=32123 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

        Was caused by:
        The boolean nis_enabled was set incorrectly.
        Description:
        Allow nis to enabled

        Allow access by executing:
        # setsebool -P nis_enabled 1
```
Делаем как рекоммендует `audit2why`:
```
[root@selinux vagrant]# setsebool -P nis_enabled 1
```
Запускаем `nginx` и проверяем какой порт он слушает:
```
[root@selinux vagrant]# systemctl start nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2021-04-02 17:29:45 UTC; 43s ago
   ...
```
```
[root@selinux vagrant]# netstat -tnlup
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      352/rpcbind
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      611/sshd
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      698/master
tcp        0      0 0.0.0.0:32123           0.0.0.0:*               LISTEN      3558/nginx: master
tcp6       0      0 :::111                  :::*                    LISTEN      352/rpcbind
tcp6       0      0 :::22                   :::*                    LISTEN      611/sshd
tcp6       0      0 ::1:25                  :::*                    LISTEN      698/master
tcp6       0      0 :::32123                :::*                    LISTEN      3558/nginx: master
...
```
Отключаем и `nginx` не запускается:
```
[root@selinux vagrant]# setsebool -P nis_enabled 0
[root@selinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
```
## 1.2 добавление нестандартного порта в имеющийся тип
Добавляем порт *32123* для протокола `http` и проверяем что он добавлен:
```
[root@selinux vagrant]# semanage port -a -t http_port_t -p tcp 32123
[root@selinux vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      32123, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```
Запускаем `nginx` и проверяем на каком порту он слушает:
```
[root@selinux vagrant]# systemctl start nginx
[root@selinux vagrant]# netstat -tnlup
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      352/rpcbind
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      611/sshd
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      698/master
tcp        0      0 0.0.0.0:32123           0.0.0.0:*               LISTEN      3644/nginx: master
...
```
Удаляем порт:
```
sudo semanage port -d -t http_port_t -p tcp 32123
```
## 1.3 формирование и установка модуля SELinux
Генерируем модуль с помощью `audit2allow`:
```
[root@selinux vagrant]# audit2allow -M http321123 --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i http321123.pp
```
Устанавливаем полученный модуль:
```
[root@selinux vagrant]# semodule -i http321123.pp
```
Запускаем `nginx` и проверяем что он работает на порту 32123:
```
[root@selinux vagrant]# systemctl start nginx
[root@selinux vagrant]# netstat -tnlup
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      352/rpcbind
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      611/sshd
tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN      698/master
tcp        0      0 0.0.0.0:32123           0.0.0.0:*               LISTEN      3644/nginx: master
...
```
## Задание 2. Обеспечить работоспособность приложения при включенном selinux
Запускаем стенд и проделываем описанный в его README запрос на изменение зоны:
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10  
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
```
Смотрим описание ошибки в логах на сервере через `audit2why` и `sealert`:
```
[root@ns01 vagrant]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1617612776.656:1932): avc:  denied  { write } for  pid=5185 comm="isc-worker0000" name="named" dev="sda1" ino=67538910 scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:named_zone_t:s0 tclass=dir permissive=0
...
```
```
[root@ns01 vagrant]# sealert -a /var/log/audit/audit.log
100% done
found 2 alerts in /var/log/audit/audit.log
--------------------------------------------------------------------------------

SELinux is preventing /usr/sbin/named from write access on the directory named.

*****  Plugin catchall_boolean (89.3 confidence) suggests   ******************
...
```
В логах указана ошибка в правах доступа у `/usr/sbin/named` к директории и файлу `named.ddns.lab.view1.jnl`.
Варианты исправления ошибки:
1. Через установку флага:
```
  setsebool -P named_write_master_zones 1
```
2. Создание и уставновка модуля через `audit2allow`
 ```
 ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000
   
 semodule -i my-iscworker0000.pp
```
3. Изменение контекста для файла `named.ddns.lab.view1.jnl` через `semanage`
```
semanage fcontext -a -t FILE_TYPE 'named.ddns.lab.view1.jnl'

where FILE_TYPE is one of the following: dnssec_trigger_var_run_t, ipa_var_lib_t, krb5_host_rcache_t, krb5_keytab_t, named_cache_t, named_log_t, named_tmp_t, named_var_run_t.

restorecon -v 'named.ddns.lab.view1.jnl'
```
Попробуем устранить проблему изменением контекста для файла `named.ddns.lab.view1.jnl`, так как это решение является наиболее точечным и не предоставляет излишние разрешения.
Файл `named.ddns.lab.view1` расположен в `/etc/named/dynamic/`, что указано в `named.conf`
Выясняем тип файла:
```
[root@ns01 /]# ll -Z /etc/named/dynamic/named.ddns.lab.view1
-rw-rw----. named named system_u:object_r:etc_t:s0       /etc/named/dynamic/named.ddns.lab.view1
```
Изменяем `FILE_TYPE` на `named_cache_t` (по умолчанию для `dynamic DNS` в `/var/named/dynamic/`):
```
[root@ns01 /]# semanage fcontext -a -t named_cache_t 'named.ddns.lab.view1.jnl'
Killed
```
```
[root@ns01 /]# restorecon -v '/etc/named/dynamic/named.ddns.lab.view1'
```
