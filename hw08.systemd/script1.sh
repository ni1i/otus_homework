#!/bin/bash

sudo cp /vagrant/monitoring.cfg /etc/sysconfig/

sudo cp /vagrant/monitoring.log /var/log/

sudo cp /vagrant/monitoring.sh /var/log/

sudo chmod +x /var/log/monitoring.sh

sudo cp /vagrant/monitoring.service /etc/systemd/system/

sudo cp /vagrant/monitoring.timer /etc/systemd/system/

sudo systemctl daemon-reload

sudo systemctl enable monitoring.timer

sudo systemctl enable monitoring.service

sudo systemctl start monitoring.timer

sudo systemctl start monitoring.service
