# ДЗ 18. Docker
* Создайте свой кастомный образ nginx на базе alpine.

* После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

* Определите разницу между контейнером и образом

* Вывод опишите в домашнем задании.

* Ответьте на вопрос: Можно ли в контейнере собрать ядро?

* Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.
---
Обновляем индекс пакетов:
```
sudo yum check-update
```
Добавляем необходимые репозитории и устанавливаем актуальную версию Docker:
```
curl -fsSL https://get.docker.com/ | sh
```
Запускаем демона Docker и проверяем статус:
```
[root@docker vagrant]# sudo systemctl start docker
[root@docker vagrant]# sudo systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-04-27 14:00:38 UTC; 24s ago
     Docs: https://docs.docker.com
 Main PID: 413 (dockerd)
    Tasks: 8
   Memory: 43.4M
   CGroup: /system.slice/docker.service
           └─413 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

Apr 27 14:00:37 docker dockerd[413]: time="2021-04-27T14:00:37.741991947Z" level=info msg="scheme \"unix\" not registered, fallback to default scheme" module=grpc
Apr 27 14:00:37 docker dockerd[413]: time="2021-04-27T14:00:37.742016839Z" level=info msg="ccResolverWrapper: sending update to cc: {[{unix:///run/containerd/containerd.sock  <nil> 0 <nil>}] <nil> <nil>}" module=grpc
Apr 27 14:00:37 docker dockerd[413]: time="2021-04-27T14:00:37.742036644Z" level=info msg="ClientConn switching balancer to \"pick_first\"" module=grpc
Apr 27 14:00:37 docker dockerd[413]: time="2021-04-27T14:00:37.880485301Z" level=info msg="Loading containers: start."
Apr 27 14:00:38 docker dockerd[413]: time="2021-04-27T14:00:38.481210264Z" level=info msg="Default bridge (docker0) is assigned with an IP address 172.17.0.0/16. Daemon option --bip can be used to set ...rred IP address"
Apr 27 14:00:38 docker dockerd[413]: time="2021-04-27T14:00:38.657552267Z" level=info msg="Loading containers: done."
Apr 27 14:00:38 docker dockerd[413]: time="2021-04-27T14:00:38.723186556Z" level=info msg="Docker daemon" commit=8728dd2 graphdriver(s)=overlay2 version=20.10.6
Apr 27 14:00:38 docker dockerd[413]: time="2021-04-27T14:00:38.723429259Z" level=info msg="Daemon has completed initialization"
Apr 27 14:00:38 docker systemd[1]: Started Docker Application Container Engine.
Apr 27 14:00:38 docker dockerd[413]: time="2021-04-27T14:00:38.830386748Z" level=info msg="API listen on /var/run/docker.sock"
Hint: Some lines were ellipsized, use -l to show in full.

```
Правим дефолтную страничку nginx (index.html) и забираем её для дальнейшего импорта в кастомный образ.
