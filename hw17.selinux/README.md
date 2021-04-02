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
Выполнение ДЗ:

Задание 1. Запустить `nginx` на нестандартном порту 3-мя разными способами: 
    
   1.1 переключатели `setsebool` 

   Устанавливаем `nginx` и пакет в который в ходит утилита `audit2why` (policycoreutils-python).
 
   Меняем порт 80 на `32123` в `/etc/nginx/nginx.conf`
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
