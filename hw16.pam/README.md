# ДЗ 16. Пользователи и группы. Авторизация и аутентификация
PAM
*  Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников

*  Дать конкретному пользователю права работать с докером и возможность рестартить докер сервис
---

## Часть 1. Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников
Устанавливаем `epel-release` и `pam_script`.
Создаём два пользователя: `user1` и `user2`, пароль у обоих `0123456`.
Создаём группу `admin`.


groupadd admin
```
Создаём пользователей `admin1` и `user1` с паролем `12345`:
```
[root@PAM vagrant]# useradd admin1
[root@PAM vagrant]# useradd user1
[root@PAM vagrant]# passwd admin1
Changing password for user admin1.
New password:
BAD PASSWORD: The password is shorter than 7 characters
Retype new password:
passwd: all authentication tokens updated successfully.
[root@PAM vagrant]# passwd user1
Changing password for user user1.
New password:
BAD PASSWORD: The password is shorter than 7 characters
Retype new password:
passwd: all authentication tokens updated successfully.
```
Добавляем пользователя `admin1` в группу `admin`:
```
usermod -aG admin admin1
```
Проверяем:
```
[root@PAM vagrant]# id admin1
uid=1004(admin1) gid=1005(admin1) groups=1005(admin1),1004(admin)
```
Устанавливаем модуль pam_script:
