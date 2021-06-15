# ДЗ 27. Фильтрация трафика - firewalld, iptables

Сценарии iptables

* реализовать knocking port

* centralRouter может попасть на ssh inetrRouter через knock скрипт пример в материалах

* добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост

* запустить nginx на centralServer
* пробросить 80й порт на inetRouter2 8080
* дефолт в инет оставить через inetRouter
* реализовать проход на 80й порт без маскарадинга
-----

За основу взят стенд ДЗ по сетевой лаборатории. Убрал сети `Office1` и `Office2` со всем содержимым и добавил второй роутер (`inetRouter2`).

`Vagrantfile` поднимает 4 VM:
 
 * `inetRouter1`
 * `inetRouter2`
 * `centralRouter`
 * `centralServer`

Доступ в интернет с `centralServer` осуществляется с `inetRouter1`.

 ## Проброс порта
 Проверяется с хостовой машины до запущенного на `centralServer` *nginx* с изменённой стартовой страницей:
```
uk@otus01:~/L27/tmp5$ curl http://localhost:8080

!!! NEW default nginx page on centralServer
```
## Knocking port
На `inetRouter1` установлена сетверная часть `knock`, на `centralRouter` - клиентская.
