#!/bin/bash

sudo yum install -y java-1.8.0-openjdk

mkdir /home/vagrant/kafka

curl https://downloads.apache.org/kafka/2.7.0/kafka_2.13-2.7.0.tgz -o /home/vagrant/kafka/kafka.tgz

cd /home/vagrant/kafka/

sudo tar -xvzf /home/vagrant/kafka/kafka.tgz --strip 1

sudo cp /home/vagrant/zookeeper.service /etc/systemd/system/

sudo cp /home/vagrant/kafka.service /etc/systemd/system/

sudo cp /home/vagrant/restart-kafka.service /etc/systemd/system/

sudo cp /home/vagrant/restart-kafka.path /etc/systemd/system/

sudo touch /home/vagrant/kafka/kafka.log

sudo chmod 777 /home/vagrant/kafka/kafka.log

sudo systemctl daemon-reload

sudo systemctl enable zookeeper.service

sudo systemctl start zookeeper.service

sudo systemctl enable kafka.service

sudo systemctl start kafka.service

sudo systemctl enable restart-kafka.service

sudo systemctl enable restart-kafka.path

sudo systemctl start restart-kafka.service

sudo systemctl start restart-kafka.path