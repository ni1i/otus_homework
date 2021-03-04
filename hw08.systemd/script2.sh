#!/bin/bash

sudo yum install -y epel-release

sudo yum install -y php php-cli mod_fcgid

sudo yum install -y spawn-fcgi

sudo sed -i 's/#SOCKET/SOCKET/' /etc/sysconfig/spawn-fcgi

sudo sed -i 's/#OPTIONS/OPTIONS/' /etc/sysconfig/spawn-fcgi

sudo cp /vagrant/spawn-fcgi.service /etc/systemd/system/spawn-fcgi.service

sudo systemctl daemon-reload

sudo systemctl enable spawn-fcgi.service

sudo systemctl start spawn-fcgi.service
