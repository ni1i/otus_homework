sudo cp /usr/lib/systemd/system/httpd.service /etc/systemd/system/httpd@.service

sudo sed -i '/^EnvironmentFile/ s/$/-%I/' /etc/systemd/system/httpd@.service

sudo echo "OPTIONS=-f conf/httpd-1.conf" > /etc/sysconfig/httpd-1

sudo echo "OPTIONS=-f conf/httpd-2.conf" > /etc/sysconfig/httpd-2

sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-1.conf

sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd-2.conf

sudo mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.old

sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd-2.conf

sudo sed -i '/ServerRoot "\/etc\/httpd"/a PidFile \/var\/run\/httpd-2.pid' /etc/httpd/conf/httpd-2.conf

sudo systemctl disable httpd

sudo systemctl daemon-reload

sudo systemctl start httpd@1

sudo systemctl start httpd@2