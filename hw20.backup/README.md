# ДЗ 20. Резервное копирование 

Настраиваем бэкапы

Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client

Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

   * Директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB.
   * Репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение
    Имя бекапа должно содержать информацию о времени снятия бекапа
   * Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов
   * Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.
   * Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение.
   * Настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов

Запустите стенд на 30 минут. Убедитесь что резервные копии снимаются. Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа. Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.

----
`Vagrantfile` поднимает две виртуальные машины: `server` и `client` и делает их первичную настройку:
*  на `server` сделан отдельный диск 2Gb (подмонтирован в `/var`) для хранения резервных копий.
*  на обоих машинах устанавливается `borg` и создаётся пользователь `borg`.

Далее на **`client`**:
- генерируем `ssh`-ключ под пользователем `borg`
```
[borg@client ~]$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/borg/.ssh/id_rsa):
Created directory '/home/borg/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/borg/.ssh/id_rsa.
Your public key has been saved in /home/borg/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:y1Xsdq592uT0gvrH0gyq2+LkQtdO68yTQCa+ZzhcNX8 borg@client
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|           .     |
|            o    |
|      . o oo     |
|     . +So.oo .  |
|      o.+oo.ooE  |
|     o =++ + B. o|
|      *o++* oo*=o|
|       *==*+ooo++|
+----[SHA256]-----+
```
Переносим содержимое открытого ключа `id_rsa.pub` с `client`  на `server` в `/home/borg/.ssh/authorized_keys`.
Проверяем, что б права у папки `/home/borg/.ssh/` были 600, файлов внутри 700. При необходимости корректируем с помощью `chmod`.

Прописываем сопоставление ip-адресов именам в `/etc/hosts` на обоих машинах:
```
192.168.11.150 server
192.168.11.151 client
```
Создаём папку для размещения резервных копий: `/var/backup/`, и устанавливаем права:
```
sudo mkdir /var/backup
sudo chmod 700 /var/backup
sudo chown borg:borg /var/backup
```
Инициализируем репозиторий для резервных копий с `client`:
```
borg init --encryption=repokey borg@server:/var/backup/Repo1
```
Создаём скрипт `script.sh`, отвечающий условию задания:

* Имя бекапа должно содержать информацию о времени снятия бекапа
* Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов
* Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.

Для теста добавлены ключи `--keep-minutely=100 --keep-hourly=20`.
```
#!/usr/bin/env bash

export BORG_RSH='ssh -i /home/borg/.ssh/id_rsa'
export BORG_PASSPHRASE=""
REPOSITORY="borg@server:/var/backup/Repo1"

borg create -v --stats $REPOSITORY::'etc_hw20-{now:%Y-%m-%d@%H:%M}' /etc

borg prune -v $REPOSITORY --prefix 'etc_hw20-' --list --keep-minutely=100 --keep-hourly=20 --keep-daily=90 --keep-monthly=12

2>&1

borg list $REPOSITORY
```
Делаем скрипт исполняемым и запускаем:
```
[borg@client ~]$ chmod +x /home/borg/script.sh
[borg@client ~]$ sh /home/borg/script.sh
Creating archive at "borg@server:/var/backup/Repo1::etc_hw20-{now:%Y-%m-%d@%H:%M}"
/etc/crypttab: open: [Errno 13] Permission denied: '/etc/crypttab'
/etc/securetty: open: [Errno 13] Permission denied: '/etc/securetty'
/etc/gshadow: open: [Errno 13] Permission denied: '/etc/gshadow'
/etc/libaudit.conf: open: [Errno 13] Permission denied: '/etc/libaudit.conf'
/etc/cron.daily/logrotate: open: [Errno 13] Permission denied: '/etc/cron.daily/logrotate'
/etc/.pwd.lock: open: [Errno 13] Permission denied: '/etc/.pwd.lock'
/etc/gshadow-: open: [Errno 13] Permission denied: '/etc/gshadow-'
/etc/shadow-: open: [Errno 13] Permission denied: '/etc/shadow-'
/etc/anacrontab: open: [Errno 13] Permission denied: '/etc/anacrontab'
/etc/cron.deny: open: [Errno 13] Permission denied: '/etc/cron.deny'
/etc/tcsd.conf: open: [Errno 13] Permission denied: '/etc/tcsd.conf'
/etc/sudo-ldap.conf: open: [Errno 13] Permission denied: '/etc/sudo-ldap.conf'
/etc/sudo.conf: open: [Errno 13] Permission denied: '/etc/sudo.conf'
/etc/sudoers: open: [Errno 13] Permission denied: '/etc/sudoers'
/etc/chrony.keys: open: [Errno 13] Permission denied: '/etc/chrony.keys'
/etc/shadow: open: [Errno 13] Permission denied: '/etc/shadow'
/etc/selinux/targeted/semanage.read.LOCK: open: [Errno 13] Permission denied: '/etc/selinux/targeted/semanage.read.LOCK'
/etc/selinux/targeted/semanage.trans.LOCK: open: [Errno 13] Permission denied: '/etc/selinux/targeted/semanage.trans.LOCK'
/etc/selinux/targeted/active: scandir: [Errno 13] Permission denied: '/etc/selinux/targeted/active'
/etc/selinux/final: scandir: [Errno 13] Permission denied: '/etc/selinux/final'
/etc/polkit-1/rules.d: scandir: [Errno 13] Permission denied: '/etc/polkit-1/rules.d'
/etc/polkit-1/localauthority: scandir: [Errno 13] Permission denied: '/etc/polkit-1/localauthority'
/etc/ssh/ssh_host_rsa_key: open: [Errno 13] Permission denied: '/etc/ssh/ssh_host_rsa_key'
/etc/ssh/ssh_host_ed25519_key: open: [Errno 13] Permission denied: '/etc/ssh/ssh_host_ed25519_key'
/etc/ssh/ssh_host_ecdsa_key: open: [Errno 13] Permission denied: '/etc/ssh/ssh_host_ecdsa_key'
/etc/ssh/sshd_config: open: [Errno 13] Permission denied: '/etc/ssh/sshd_config'
/etc/dhcp: scandir: [Errno 13] Permission denied: '/etc/dhcp'
/etc/audisp: scandir: [Errno 13] Permission denied: '/etc/audisp'
/etc/grub.d: scandir: [Errno 13] Permission denied: '/etc/grub.d'
/etc/sysconfig/ip6tables-config: open: [Errno 13] Permission denied: '/etc/sysconfig/ip6tables-config'
/etc/sysconfig/iptables-config: open: [Errno 13] Permission denied: '/etc/sysconfig/iptables-config'
/etc/sysconfig/network-scripts/ifcfg-eth1: open: [Errno 13] Permission denied: '/etc/sysconfig/network-scripts/ifcfg-eth1'
/etc/sysconfig/crond: open: [Errno 13] Permission denied: '/etc/sysconfig/crond'
/etc/sysconfig/ebtables-config: open: [Errno 13] Permission denied: '/etc/sysconfig/ebtables-config'
/etc/sysconfig/sshd: open: [Errno 13] Permission denied: '/etc/sysconfig/sshd'
/etc/wpa_supplicant/wpa_supplicant.conf: open: [Errno 13] Permission denied: '/etc/wpa_supplicant/wpa_supplicant.conf'
/etc/pki/rsyslog: scandir: [Errno 13] Permission denied: '/etc/pki/rsyslog'
/etc/pki/CA/private: scandir: [Errno 13] Permission denied: '/etc/pki/CA/private'
/etc/security/opasswd: open: [Errno 13] Permission denied: '/etc/security/opasswd'
/etc/openldap/certs/password: open: [Errno 13] Permission denied: '/etc/openldap/certs/password'
/etc/gssproxy/99-nfs-client.conf: open: [Errno 13] Permission denied: '/etc/gssproxy/99-nfs-client.conf'
/etc/gssproxy/gssproxy.conf: open: [Errno 13] Permission denied: '/etc/gssproxy/gssproxy.conf'
/etc/gssproxy/24-nfs-server.conf: open: [Errno 13] Permission denied: '/etc/gssproxy/24-nfs-server.conf'
/etc/firewalld: scandir: [Errno 13] Permission denied: '/etc/firewalld'
/etc/audit: scandir: [Errno 13] Permission denied: '/etc/audit'
/etc/sudoers.d: scandir: [Errno 13] Permission denied: '/etc/sudoers.d'
------------------------------------------------------------------------------
Archive name: etc_hw20-2021-04-16@12:52
Archive fingerprint: 21b6c4624d022299ba822f2b73ead8f592460f38da1a3c9cf8fa5f0b830dc098
Time (start): Fri, 2021-04-16 12:52:26
Time (end):   Fri, 2021-04-16 12:52:28
Duration: 1.93 seconds
Number of files: 427
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               17.98 MB              6.04 MB              6.03 MB
All archives:               17.98 MB              6.04 MB              6.03 MB

                       Unique chunks         Total chunks
Chunk index:                     420                  428
------------------------------------------------------------------------------
Keeping archive: etc_hw20-2021-04-16@12:52            Fri, 2021-04-16 12:52:26 [21b6c4624d022299ba822f2b73ead8f592460f38da1a3c9cf8fa5f0b830dc098]
etc_hw20-2021-04-16@12:52            Fri, 2021-04-16 12:52:26 [21b6c4624d022299ba822f2b73ead8f592460f38da1a3c9cf8fa5f0b830dc098]

```
Создаём systemd службу:
```
vi /etc/systemd/system/borgbackup.service
```
```
[Unit]
Description=Borg

[Service]
Type=simple
ExecStart=/home/borg/script.sh
```
и таймер для запуска скрипта каждые 5 минут:
```
vi /etc/systemd/system/borgbackup.timer
```
```
[Unit]
Description=Borg

[Timer]
OnUnitActiveSec=300s
OnBootSec=10s

[Install]
WantedBy=timers.target
```
Даём права на запуск службы и таймера.
Перегружаем службы и запускаем таймер:
```
[root@client .ssh]# systemctl daemon-reload
[root@client .ssh]# systemctl enable borgbackup.timer
[root@client .ssh]# systemctl start borgbackup.timer
```
Проверяем свои резервные копии на `server` с `client`:
```
[borg@client vagrant]# borg list borg@server:/var/backup/Repo1
etc_hw20-2021-04-19@17:29            Mon, 2021-04-19 17:29:37 [913f7f437d4136c7f9737a9533d7112ff5775c2c968e677b9c4a2b86a90242db]
etc_hw20-2021-04-19@17:30            Mon, 2021-04-19 17:30:19 [66f730124f5b9b0cd08d55de920cb0c21059377312a0b471f0b3233bc4528017]
etc_hw20-2021-04-19@17:47            Mon, 2021-04-19 17:47:21 [fd05248f7e520293a8f13c4f9ae9b28cbac4654d566e63165d50fe9751fd8f76]
etc_hw20-2021-04-19@17:53            Mon, 2021-04-19 17:53:13 [9cf236d137a9469e0644719af3973359224630f055e03cb86944890f46efce08]
```
Проверяем какие файлы внутри конкретной копии:
```
]
[borg@client vagrant]# borg list borg@server:/var/backup/Repo1::etc_hw20-2021-04-19@17:47 | less
drwxr-xr-x root   root          0 Wed, 2018-04-11 04:59:55 etc/opt
-rw-r--r-- root   root         28 Wed, 2013-02-27 20:29:02 etc/ld.so.conf
-rw-r--r-- root   root       1634 Tue, 2012-12-25 03:02:13 etc/rpc
-rw-r--r-- root   root       1938 Tue, 2020-03-31 22:09:52 etc/nsswitch.conf.bak
lrwxrwxrwx root   root         11 Mon, 2021-04-19 13:28:56 etc/init.d -> rc.d/init.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc0.d -> rc.d/rc0.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc1.d -> rc.d/rc1.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc2.d -> rc.d/rc2.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc3.d -> rc.d/rc3.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc4.d -> rc.d/rc4.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc5.d -> rc.d/rc5.d
lrwxrwxrwx root   root         10 Mon, 2021-04-19 13:28:56 etc/rc6.d -> rc.d/rc6.d
drwxr-xr-x root   root          0 Tue, 2014-06-10 04:03:22 etc/popt.d
drwxr-xr-x root   root          0 Mon, 2021-04-19 13:29:31 etc/rc.d
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc2.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc2.d/S10network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc2.d/K50netconsole -> ../init.d/netconsole
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc6.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc6.d/K90network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc6.d/K50netconsole -> ../init.d/netconsole
-rw-r--r-- root   root        473 Tue, 2021-02-02 16:34:16 etc/rc.d/rc.local
drwxr-xr-x root   root          0 Mon, 2021-04-19 13:29:38 etc/rc.d/init.d
-rw-r--r-- root   root       1160 Tue, 2021-02-02 16:34:15 etc/rc.d/init.d/README
-rw-r--r-- root   root      18281 Fri, 2020-05-22 10:44:33 etc/rc.d/init.d/functions
-rwxr-xr-x root   root       4569 Fri, 2020-05-22 10:44:33 etc/rc.d/init.d/netconsole
-rwxr-xr-x root   root       7928 Fri, 2020-05-22 10:44:33 etc/rc.d/init.d/network
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc3.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc3.d/S10network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc3.d/K50netconsole -> ../init.d/netconsole
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc0.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc0.d/K90network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc0.d/K50netconsole -> ../init.d/netconsole
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc4.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc4.d/S10network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc4.d/K50netconsole -> ../init.d/netconsole
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc1.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc1.d/K90network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc1.d/K50netconsole -> ../init.d/netconsole
drwxr-xr-x root   root          0 Tue, 2020-10-13 15:46:48 etc/rc.d/rc5.d
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:06:33 etc/rc.d/rc5.d/S10network -> ../init.d/network
lrwxrwxrwx root   root         20 Thu, 2020-04-30 22:06:33 etc/rc.d/rc5.d/K50netconsole -> ../init.d/netconsole
-rw-r--r-- root   root         94 Fri, 2017-03-24 16:39:09 etc/GREP_COLORS
-rw-r--r-- root   root      12288 Mon, 2021-04-19 13:25:58 etc/aliases.db
-rw-r--r-- root   root         71 Mon, 2021-04-19 13:26:21 etc/resolv.conf
...
```
Логи можно посмотреть в `journalctl`:
```
journalctl -u borgbackup
```
Создадим тестовый файл `testfile` в директории, которую резервируем, подождём 5 минут, проверим что он есть в резервной копии.
```
[borg@client etc]# borg list borg@server:/var/backup/Repo1
etc_hw20-2021-04-19@17:29            Mon, 2021-04-19 17:29:37 [913f7f437d4136c7f9737a9533d7112ff5775c2c968e677b9c4a2b86a90242db]
etc_hw20-2021-04-19@17:30            Mon, 2021-04-19 17:30:19 [66f730124f5b9b0cd08d55de920cb0c21059377312a0b471f0b3233bc4528017]
etc_hw20-2021-04-19@17:47            Mon, 2021-04-19 17:47:21 [fd05248f7e520293a8f13c4f9ae9b28cbac4654d566e63165d50fe9751fd8f76]
etc_hw20-2021-04-19@17:53            Mon, 2021-04-19 17:53:13 [9cf236d137a9469e0644719af3973359224630f055e03cb86944890f46efce08]
etc_hw20-2021-04-19@17:59            Mon, 2021-04-19 17:59:13 [33ece59cd01a49d6725d76b93a706ef4f33d2d4678964ff2eb1d853c5fbd5bd0]
```
```
[borg@client ~]$ borg list borg@server:/var/backup/Repo1::etc_hw20-2021-04-19@17:59 | grep test
-rw-r--r-- root   root          8 Mon, 2021-04-19 17:57:13 etc/testfile
-rw-r--r-- root   root       1050 Mon, 2017-10-02 17:44:08 etc/yum.repos.d/epel-testing.repo
-rw-r--r-- root   root        279 Tue, 2020-05-12 16:27:41 etc/yum/pluginconf.d/fastestmirror.conf

```
Удалим его и восстановим из резервной копии:
```
[borg@client ~]$ borg extract --list borg@server:/var/backup/Repo1::etc_hw20-2021-04-19@18:17 etc/testfile
etc/testfile
```
Файл успешно восстановлен из архива.