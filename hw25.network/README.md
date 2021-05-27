# ДЗ 25. Архитектура сетей

разворачиваем сетевую лабораторию
otus-linux

Vagrantfile - для стенда урока 9 - Network

Дано

https://github.com/erlong15/otus-linux/tree/network (ветка network)

Vagrantfile с начальным построением сети

    inetRouter
    centralRouter
    centralServer

тестировалось на virtualbox
Планируемая архитектура

построить следующую архитектуру

Сеть office1

    192.168.2.0/26 - dev
    192.168.2.64/26 - test servers
    192.168.2.128/26 - managers
    192.168.2.192/26 - office hardware

Сеть office2

    192.168.1.0/25 - dev
    192.168.1.128/26 - test servers
    192.168.1.192/26 - office hardware

Сеть central

    192.168.0.0/28 - directors
    192.168.0.32/28 - office hardware
    192.168.0.64/26 - wifi

Office1 ---\
                   -----> Central --IRouter --> internet
Office2----/

Итого должны получится следующие сервера

    inetRouter
    centralRouter
    office1Router
    office2Router
    centralServer
    office1Server
    office2Server

Теоретическая часть

    Найти свободные подсети
    Посчитать сколько узлов в каждой подсети, включая свободные
    Указать broadcast адрес для каждой подсети
    проверить нет ли ошибок при разбиении

Практическая часть

    Соединить офисы в сеть согласно схеме и настроить роутинг
    Все сервера и роутеры должны ходить в инет черз inetRouter
    Все сервера должны видеть друг друга
    у всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи
    при нехватке сетевых интервейсов добавить по несколько адресов на интерфейс

----
## Теоретическая часть ##
Свободные подсети, количество узлов в каждой подсети и broadcast:

**Сеть office1**:

Свободных подсетей нет.

Подсеть | Имя | Всего узлов | Broadcast 
--- | --- | --- | ---
192.168.2.0/26 | dev | 62 | 192.168.2.63
192.168.2.64/26 | test servers | 62 | 192.168.2.127
192.168.2.128/26 | managers | 62 | 192.168.2.191
192.168.2.192/26 | office hardware | 62 | 192.168.2.255

**Сеть office2**

Свободных подсетей нет.

Подсеть | Имя | Всего узлов | Broadcast 
--- | --- | --- | ---
192.168.1.0/25 | dev | 126 | 192.168.1.127
192.168.1.128/26 | test servers | 62 | 192.168.1.191
192.168.1.192/26 | office hardware | 62 | 192.168.1.255

**Сеть central**

Подсеть | Имя | Всего узлов | Broadcast 
--- | --- | --- | ---
192.168.0.0/28 | directors |  14 | 192.168.0.15
192.168.0.16/28 | СВОБОДНАЯ | 14 | 192.168.0.31
192.168.0.32/28 | office hardware | 14 | 192.168.0.47
192.168.0.48/28 | СВОБОДНАЯ | 14 | 192.168.0.63
192.168.0.64/26 | wifi | 62 | 192.168.0.127
192.168.0.128/25 | СВОБОДНАЯ | 126 | 192.168.0.255

Ошибок при разбиении не выявил.

## Практическая часть ##
Для выполнения ДЗ в стендовый Vagrantfile с тремя машинами (inetRouter, centralRouter, centralServer) добавлены ещё четыре:

    office1Router
    office2Router
    office1Server
    office2Server

На схеме представлена структура получившейся сети и указаны интерфейсы.

![network](network.jpg)

В Vagrantfile добавлены интерфейсы и маршруты для eth1.

## inetRouter ###
```
{ip: '192.168.255.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"}
```
## centralRouter ##
```
{ip: '192.168.255.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
{ip: '192.168.0.1', adapter: 3, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
{ip: '192.168.0.33', adapter: 4, netmask: "255.255.255.240", virtualbox__intnet: "hw-net"},
{ip: '192.168.0.65', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "mgt-net"},
{ip: '192.168.255.5', adapter: 6, netmask: "255.255.255.252", virtualbox__intnet: "c-o1"},
{ip: '192.168.255.9', adapter: 7, netmask: "255.255.255.252", virtualbox__intnet: "c-o2"}
```

## centralServer ##

```
{ip: '192.168.0.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
```

## office1Router ##
```
{ip: '192.168.255.6', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "c-o1"},
{ip: '192.168.2.1', adapter: 3, netmask: "255.255.255.192", virtualbox__intnet: "o1-serv"},
{ip: '192.168.2.65', adapter: 4, netmask: "255.255.255.192", virtualbox__intnet: "test-servers"},
{ip: '192.168.2.129', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "managers"},
{ip: '192.168.2.193', adapter: 6, netmask: "255.255.255.192", virtualbox__intnet: "office-hardware"}
```
## office1Server ##
```
{ip: '192.168.2.2', adapter: 2, netmask: "255.255.255.192", virtualbox__intnet: "o1-serv"}
```
## office2Router ##
```
{ip: '192.168.255.10', adapter:2, netmask: "255.255.255.252", virtualbox__intnet: "c-o2"},
{ip: '192.168.1.1', adapter: 3, netmask: "255.255.255.128", virtualbox__intnet: "o2-serv"},
{ip: '192.168.1.129', adapter: 4, netmask: "255.255.255.192", virtualbox__intnet: "test-servers"},
{ip: '192.168.1.193', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "office-hardware"}
```
## office2Server ##
```
{ip: '192.168.1.2', adapter: 2, netmask: "255.255.255.128", virtualbox__intnet: "o2-serv"}
```
На всех новых серверах отключен дефолт на NAT (eth0).



