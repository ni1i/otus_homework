sudo yum update -y
sudo yum install -y ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel grub2 kernel-devel wget centos-release-scl
sudo yum install -y devtoolset-7-gcc*
scl enable devtoolset-7 bash
sudo wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.10.11.tar.xz
sudo tar -xvf linux-5.10.11.tar.xz
cd linux-5.10.11
sudo cp -v /boot/config-$(uname -r) .config
sudo make olddefconfig
sudo make -j7
sudo make -j7 modules
sudo make -j7 install
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo reboot