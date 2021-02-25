#!/bin/bash

yum install -y nfs-utils

systemctl start rpcbind
systemctl enable rpcbind

mkdir /mnt/nfs_share

mount -t nfs 192.168.50.10:/var/nfs_share/ /mnt/nfs_share/

echo "192.168.50.10:/var/nfs_share/ /mnt/nfs_share/ nfs defaults 0 0" >> /etc/fstab
