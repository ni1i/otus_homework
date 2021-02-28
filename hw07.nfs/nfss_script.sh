#!/bin/bash

yum install -y nfs-utils

mkdir /var/nfs_share
chmod -R 777 /var/nfs_share/
mkdir /var/nfs_share/upload
chmod -R 777 /var/nfs_share/upload

systemctl enable rpcbind nfs-server

systemctl start rpcbind nfs-server

echo "/var/nfs_share 192.168.50.11(rw,root_squash,no_all_squash)" > /etc/exports

exportfs -r

systemctl start firewalld
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload
