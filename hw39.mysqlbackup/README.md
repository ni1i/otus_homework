# ДЗ 39. MySQL: Backup + Репликация

репликация mysql

В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp

Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:

| bookmaker          |

| competition        |

| market             |

| odds               |

| outcome

*    Настроить GTID репликацию x варианты которые принимаются к сдаче

*    рабочий вагрантафайл
*    скрины или логи SHOW TABLES
*    конфиги
*    пример в логе изменения строки и появления строки на реплике


---

Стендовый `Vagrantfile` поднимает 2 `VM` (*master* и *slave*).

Устанавливаем репозиторий `percona`:

```
[root@master ~]$ yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
```
Устанавливаем Percona Server:

```
[root@master ~]$ yum install Percona-Server-server-57 -y
```
Копируем конфигурацию из `/vagrant/conf.d` в `/etc/my.cnf.d/`:
```
[root@master vagrant]# cp /vagrant/conf/conf.d/* /etc/my.cnf.d/
```

Запускаем службу `mysql`:
```
[root@master vagrant]# systemctl start mysql
```
Выясняем пароль, сгенерированный автоматически для пользователя `root`, хранящийся в `/var/log/mysqld.log`:
```
[root@master vagrant]# cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
.ZAX/Sx2Orsk
```
Подключимся к `mysql` и изменяем пароль:
```
[root@master vagrant]# mysql -uroot -p'.ZAX/Sx2Orsk'
mysql> ALTER USER USER() IDENTIFIED BY 'W@IZ]^y,wPY9';
Query OK, 0 rows affected (0.01 sec)
```
Меняем атрибут `server-id` на *slave* на *2* в конфигурационном файле `01-base.cnf` и проверяем, что они различаются с *master*.

*Master*:
```
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)
```
*Slave*:
```
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.00 sec)
```
Убеждаемся, что `GTID` включён:
```
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.00 sec)
```
Создаём тестовую базу *bet*, загружаем в неё дамп и проверяем:
```
mysql> CREATE DATABASE bet;
Query OK, 1 row affected (0.01 sec)
mysql> exit
Bye
[root@master vagrant]# mysql -uroot -p -D bet < /vagrant/bet.dmp
Enter password:
[root@master vagrant]# mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 15
Server version: 5.7.35-38-log Percona Server (GPL), Release 38, Revision 3692a61

Copyright (c) 2009-2021 Percona LLC and/or its affiliates
Copyright (c) 2000, 2021, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)
```
Создаём пользователя для репликации, назначаем права и проверяем:
```
mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2021';
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
1 row in set (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '!OtusLinux2021';
Query OK, 0 rows affected, 1 warning (0.01 sec)
[root@master vagrant]# mysql -e "select user,host,repl_slave_priv from mysql.user where user='repl';"
+------+------+-----------------+
| user | host | repl_slave_priv |
+------+------+-----------------+
| repl | %    | Y               |
+------+------+-----------------+
```
Создаём дамп базы, исключая таблицы `events_on_demand` и `v_same_event`, как было указано в ДЗ и смотрим результат:
```
[root@master vagrant]# mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -p > master.sql
Enter password:
Warning: A partial dump from a server that has GTIDs will by default include the GTIDs of all transactions, even those that changed suppressed parts of the database. If you don't want to restore GTIDs, pass --set-gtid-purged=OFF. To make a complete dump, pass --all-databases --triggers --routines --events.
[root@master vagrant]# ls -l
total 968
-rw-r--r--. 1 root root 990636 Nov 10 09:25 master.sql
```
Файл дампа готов, теперь готовим *slave*.
Раскомментируем в `/etc/my.cnf.d/05-binlog.cnf` строки:
```
#replicate-ignore-table=bet.events_on_demand
#replicate-ignore-table=bet.v_same_event
```
Переписываем дамп с *master* на *slave*.
Проверяем наличие базы и её структуру:
