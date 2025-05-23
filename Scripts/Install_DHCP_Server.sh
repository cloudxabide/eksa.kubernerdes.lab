#!/bin/bash

#     Purpose:
#        Date:
#      Status: Complete/Done
# Assumptions:
#       Notes: Do not implement the DHCP Server until AFTER you deploy the cluster

# Install the ISC DHCP Server package
sudo apt install -y isc-dhcp-server

# Disable/mask any notification about subnets that are not configured
sed -i -e 's/INTERFACESv4=""/INTERFACESv4="eno1"/g' /etc/default/isc-dhcp-server

sudo cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig
curl https://raw.githubusercontent.com/cloudxabide/eksa.kubernerdes.lab/refs/heads/main/Files/etc_dhcp_dhcpd.conf | sudo tee /etc/dhcp/dhcpd.conf
curl https://raw.githubusercontent.com/cloudxabide/eksa.kubernerdes.lab/refs/heads/main/Files/etc_dhcp_dhcpd-hosts.conf | sudo tee /etc/dhcp/dhcpd-hosts.conf

sudo systemctl enable isc-dhcp-server.service --now
sudo systemctl --no-page status isc-dhcp-server.service

journalctl -u isc-dhcp-server.service
exit 0

# Follow the log
journalctl -f -u isc-dhcp-server.service
