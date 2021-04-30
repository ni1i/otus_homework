# ДЗ 18. Docker
* Создайте свой кастомный образ nginx на базе alpine.

* После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)

* Определите разницу между контейнером и образом

* Вывод опишите в домашнем задании.

* Ответьте на вопрос: Можно ли в контейнере собрать ядро?

* Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.
---
Ссылка на собранный образ в `Dockerhub`: **`https://hub.docker.com/repository/docker/ni1i/nginx_my`**

Для запуска образа:
```
docker pull ni1i/nginx_my
docker run -d -p 8080:80 ni1i/nginx_my
```

Описание ДЗ:

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
Правим дефолтную страничку nginx (index.html) и забираем её для дальнейшего импорта в кастомный образ, кладём в папку `html`.
Готовим `Dockerfile`:
```
FROM nginx:alpine
COPY ./default.conf /etc/nginx/conf.d/
COPY html /usr/share/nginx/html
```
и `default.conf` для `nginx`:
```
server {
    listen       8080;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```

Собираем образ:
```
[root@docker vagrant]# docker build -t nginx_my:otus .
Sending build context to Docker daemon   21.5kB
Step 1/3 : FROM nginx:alpine
 ---> a64a6e03b055
Step 2/3 : COPY ./default.conf /etc/nginx/conf.d/
 ---> Using cache
 ---> 091c5cc993ee
Step 3/3 : COPY html /usr/share/nginx/html
 ---> 07be09cd175c
Successfully built 07be09cd175c
Successfully tagged nginx_my:otus

```
Находим собранный образ и запускаем его на порту 8080:
```
[root@docker vagrant]docker imagesss
REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
nginx_my     otus      07be09cd175c   About a minute ago   22.6MB
[root@docker vagrant]# docker run -d -p 8080:80 07be09cd175c
3c7b866e2cbac6d764915dcc7ef6ee17d96da5dc9d5e9e4907a146494869c08a
```
Заходим в запущенный образ:
```
[root@docker vagrant]# docker exec -it 259197872a0406260db0fe3e2da31ce31b7cb724cfe12a780dbe9cd4172deae sh
/ #
```
Смотрим на нашу изменённую страницу:
```
/ # curl http://localhost:8080
CTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>###NEW DAFAULT PAGE###</title>
  <style rel="stylesheet" type="text/css">
...
```
Заливаем полученный контейнер в `dockerhub`:
```
[root@docker vagrant]# docker push ni1i/nginx_my
Using default tag: latest
The push refers to repository [docker.io/ni1i/nginx_my]
0dea9115714c: Pushed
310c68a1c699: Pushed
4689e8eca613: Mounted from library/nginx
3480549413ea: Mounted from library/nginx
3c369314e003: Mounted from library/nginx
4531e200ac8d: Mounted from library/nginx
ed3fe3f2b59f: Mounted from library/nginx
b2d5eeeaba3a: Mounted from library/nginx
latest: digest: sha256:fbe2872fddee1ba01c6119ca762e955c46495ccabdb83262b92b2fd800b0871e size: 1983
```
