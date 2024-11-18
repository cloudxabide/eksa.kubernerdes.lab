#!/bin/bash
#
#     Purpose: Update a "vanilla" Ubuntu install for demo 
#        Date: 2024-07-18
#      Status: GTG | Needs validation 
# Assumptions: You used Ubuntu 22.04 Server as your base OS
#        Todo:

# Update sudo and modify user
cat << EOF1 | sudo tee /etc/sudoers.d/ubuntu-nopasswd-all
ubuntu ALL=(ALL) NOPASSWD: ALL
EOF1

# Install and update web server
sudo apt install -y apache2 php libapache2-mod-php php-mysql
sudo systemctl enable apache2 --now
sudo gpasswd -a ubuntu www-data
wget https://events.linuxfoundation.org/wp-content/uploads/2024/03/KubeCon_10thAnniversary_Sticker.png -O /var/www/html/KubeCon_10thAnniversary_Sticker.png

# Update GRUB for serial console
## NOTE: THIS NEEDS TO BE TESTED
sudo cp /etc/default/grub /etc/default/grub-`date +%F`
sudo sed -i -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=""/## GRUB_CMDLINE_LINUX_DEFAULT=""/g' /etc/default/grub
sudo sed -i -e 's/^GRUB_CMDLINE_LINUX=""/## GRUB_CMDLINE_LINUX=""\nGRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"/g' /etc/default/grub
sudo sed -i -e 's/^GRUB_TERMINAL=console/## GRUB_TERMINAL=console\nGRUB_TERMINAL="console serial"\nGRUB_SERIAL_COMMAND="serial --speed=115200"/g' /etc/default/grub
sudo update-grub

# Enable DHCP on anticipated networking interface
## NOTE: THIS NEEDS IMPROVEMENT to enable DHCP on ANY interface
cat << EOF2 | tee /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity' - manually updated
network:
  ethernets:
    ens33:
      dhcp4: true
    enp1s0:
      dhcp4: true
  version: 2
EOF2


