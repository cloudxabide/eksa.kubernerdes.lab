#!/bin/bash
#
#     Purpose: Update a "vanilla" Red Hat Enterprise Linux install for demo 
#        Date: 2024-07-18
#      Status: GTG | Needs validation 
# Assumptions: You used RHEL 8 
#        Todo:

# Check whether Secure Boot is enabled for the VM
mokutil --sb-state

# Update sudo and modify user
cat << EOF1 | sudo tee /etc/sudoers.d/mansible-nopasswd-all
mansible ALL=(ALL) NOPASSWD: ALL
EOF1

# Install and update web server
PACKAGES="
SERVICES="httpd"
for SVC in $SERVICES
do
  systemctl enable --now $SVC
done
# Update Local Firewall

TCP_PORTS="80"
UDP_PORTS="80"
for PORT in $TCP_PORTS
do
  sudo firewall-cmd --permanent --add-port=${PORT}/tcp
done
for PORT in $UDP_PORTS
do
  sudo firewall-cmd --permanent --add-port=${PORT}/udp
done
for SERVICE in $SERVICES
do
  sudo firewall-cmd --permanent --add-service=${SERVICE}
done
sudo firewall-cmd --reload
sudo firewall-cmd --list-all

get https://events.linuxfoundation.org/wp-content/uploads/2024/03/KubeCon_10thAnniversary_Sticker.png -O /var/www/html/KubeCon_10thAnniversary_Sticker.png

# Update GRUB for serial console
## NOTE: THIS NEEDS TO BE TESTED
sudo cp /etc/default/grub /etc/default/grub-`date +%F`
sudo sed -i -e 's/quiet/quiet console=tty0 console=ttyS0,115200/g' /etc/default/grub
sed -i 's/GRUB_TERMINAL_OUTPUT="console"/GRUB_TERMINAL="console serial"/g' /etc/default/grub



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


