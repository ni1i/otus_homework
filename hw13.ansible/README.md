# ДЗ 13. Автоматизация администрирования. Ansible
Первые шаги с Ansible

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:

   * необходимо использовать модуль yum/apt
   * конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
   * после установки nginx должен быть в режиме enabled в systemd
   * должен быть использован notify для старта nginx после установки
   * сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible

Домашнее задание считается принятым, если:

   * предоставлен Vagrantfile и готовый playbook/роль ( инструкция по запуску стенда, если посчитаете необходимым )
   * после запуска стенда nginx доступен на порту 8080
   * при написании playbook/роли соблюдены перечисленные в задании условия

---
На головной машине установили `python 2.7.18 (python -V)` и `ansible 2.9.6 (ansible --version)`. На управляемой машине установлен `python 2.7.5`.

## Часть 1

Узнаём параметры ssh-config:
```
uk@otus01:~/L13/Ansible$ vagrant ssh-config
Host nginx
  HostName 127.0.0.1
  User vagrant
  Port 2200
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/uk/L13/Ansible/.vagrant/machines/nginx/virtualbox/private_key
  IdentitiesOnly yes
  LogLevel FATAL
```
Создаём `inventory` файл:
```
[web]
nginx ansible_host=127.0.0.1 ansible_port=2200 ansible_user=vagrant ansible_private_key_file=/home/uk/L13/Ansible/.vagrant/machines/nginx/virtualbox/private_key
```
Кладём `inventory` в `/home/uk/L13/Ansible/staging/hosts` и проверяем управление хостом через `ansible`:

```
uk@otus01:~/L13/Ansible$ ansible nginx -i staging/hosts -m ping
The authenticity of host '[127.0.0.1]:2200 ([127.0.0.1]:2200)' can't be established.
ECDSA key fingerprint is SHA256:uON/pTWBm/zKkPasFO4dvh5g/vw5x53DA6PdjptkS0g.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```
Создаём файл `ansible.cfg` в текущем каталоге:
```
[defaults]
inventory = staging/hosts
remote_user = vagrant
host_key_checking = False
retry_files_enabled = False
```
Убираем из `inventory` информацию о пользователе:
```
[web]
nginx ansible_host=127.0.0.1 ansible_port=2200 ansible_private_key_file=/home/uk/L13/Ansible/.vagrant/machines/nginx/virtualbox/private_key
```
Проверяем, что управляемый хост доступен без явного указания `inventory` файла:
```
uk@otus01:~/L13/Ansible$ ansible nginx -m ping
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
```
Проверяем какое ядро установлено на хосте:
```
uk@otus01:~/L13/Ansible$ ansible nginx -m command -a "uname -r"
nginx | CHANGED | rc=0 >>
3.10.0-1127.el7.x86_64
```
Проверяем статус `firewalld`:
```
uk@otus01:~/L13/Ansible$ ansible nginx -m systemd -a name=firewalld
nginx | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "name": "firewalld",
    "status": {
        "ActiveEnterTimestampMonotonic": "0",
        "ActiveExitTimestampMonotonic": "0",
        "ActiveState": "inactive",
        ...
```
Устанавливаем пакет epel-release на хост:
```
uk@otus01:~/L13/Ansible$ ansible nginx -m yum -a "name=epel-release state=present" -b
nginx | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": true,
    ...
```
Создаём `playbook (epel.yml)`, который устанавливает пакет `epel-release` с содержимым:
```
---
- name: Install EPEL Repo
  hosts: nginx
  become: true
  tasks:
   - name: Install EPEL Repo package from standard repo
     yum:
      name: epel-release
      state: present
```
Запускаем `playbook`:
```
uk@otus01:~/L13/Ansible$ ansible-playbook epel.yml

PLAY [Install EPEL Repo] ***************************************************************************************************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************************************************************************************************************
ok: [nginx]

TASK [Install EPEL Repo package from standard repo] ************************************************************************************************************************************************************************
ok: [nginx]

PLAY RECAP *****************************************************************************************************************************************************************************************************************
nginx                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
Если выполнить команду `ansible nginx -m yum -a "name=epel-release state=absent" -b`, то пакет epel-release принудительно установится.

## Часть 2. Написание playbook для установки nginx

Создаём файл nginx.yml:
```
---
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  
  tasks:
    - name: NGINX | Install EPEL Repo package from standart repo
      yum:
        name: epel-release
        state: present
      tags:
        - epel-package
        - packages

    - name: NGINX | Install NGINX package from EPEL Repo
      yum:
        name: nginx
        state: latest
      tags:
        - nginx-package
        - packages
```
Проверим все теги `playbook`'a:
```
uk@otus01:~/L13/Ansible$ ansible-playbook nginx.yml --list-tags

playbook: nginx.yml

  play #1 (nginx): NGINX | Install and configure NGINX  TAGS: []
      TASK TAGS: [epel-package, nginx-package, packages]
```      
Запустим только установку nginx:
