# ДЗ 16. Пользователи и группы. Авторизация и аутентификация
PAM
*  Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

*  Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис
---

## Часть 1. Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников
Vagrantfile поднимает машину и производит следующие действия:
Устанавливает `epel-release` и `pam_script`.
Создаёт два пользователя: `user1` и `user2`, пароль у обоих `0123456`.
Создаёт группу `admin` и добавляет в неё пользователя `user1`.
Правит `/etc/pam.d/sshd`, добавляя `auth  required  pam_script.so`.
Создаёт `/etc/pam_script` с содержанием:
```
#!/bin/bash
if [[ `grep $PAM_USER /etc/group | grep 'admin'` ]]
then
exit 0
fi
if [[ `date +%u` > 5 ]]
then
exit 1
fi
```
Тут указано условие на доступ для группы `admin`:
```
...
`date +%u` > 5
...
```
Даёт разрешение на запуск скрипта `/etc/pam_script` и перегружаем `sshd`.
Для проверки можно либо дождаться выходных, либо изменить дату, либо откорректировать условие (например, не пускать со среды) и поробовать зайти под обоими созданными пользователями.
Пользователя `user2` не пускает, так как его нет в группе `admin`.
```
uk@otus01:~/L16$ ssh user2@192.168.11.150
user2@192.168.11.150's password: 
Permission denied, please try again.
```
Пользователя `user1` - пускает.
```
uk@otus01:~/L16$ ssh user1@192.168.11.150
user1@192.168.11.150's password: 
Last login: Thu Apr  1 07:51:49 2021 from 192.168.11.1
```

## Часть 2.  Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис
Наш `Vagrantfile` во второй части `shell` скрипта устанавливает и стартует `docker`:
```
sudo yum check-update
curl -fsSL https://get.docker.com/ | sh
sudo systemctl start docker
```
Включает пользователя `user1` в группу `docker`
```
sudo usermod -aG docker user1
```
Устанавливает docker-compose и задаём права на папку:
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
Побавляет ссылку.
```
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
Для того, что бы пользоветель `user1` мог перезапускать службу `doker` делаем правило `/etc/polkit-1/rules.d/10-docker.rules` c содержимым:
```
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "docker.service" &&
        action.lookup("verb") == "restart" &&
	subject.user == "user1") {
        return polkit.Result.YES;
    }
});
```
Обновляем `systemd` до версии 234.
После проделанных манипуляций у нас установлен `docker` и `docker-compose` и у пользователя `user1` есть права на перезапуск службы и работу с `docker`.
```
uk@otus01:~/L16$ ssh user1@192.168.11.150
user1@192.168.11.150's password:
Last login: Thu Apr  1 10:00:54 2021 from 192.168.11.1
[user1@PAM ~]$ docker --version
Docker version 20.10.5, build 55c4c88
[user1@PAM ~]$ docker images
REPOSITORY   TAG       IMAGE ID   CREATED   SIZE
[user1@PAM ~]$

```
