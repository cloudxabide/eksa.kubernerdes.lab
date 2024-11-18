#!/bin/bash

#     Purpose: Install BIND9 and Zone Files for my Subnet/Domain
#        Date:
#      Status: GTG | Complete/Done
# Assumptions: You have sourced the ~/ENV.vars file
#        Todo:

sudo apt install -y bind9 bind9utils bind9-doc
sudo sed -i -e 's/bind/bind -4/g' /etc/default/named

sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
curl ${REPO}main/Files/etc_bind_named.conf.options | sudo tee /etc/bind/named.conf.options

# Add all of the zone files to the BIND config
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
curl ${REPO}main/Files/etc_bind_named.conf.local | sudo tee /etc/bind/named.conf.local

sudo systemctl enable named.service --now

sudo mkdir -p /etc/bind/zones
for ZONE in 12 13 14 15
do 
  curl ${REPO}main/Files/etc_bind_zones_db.$ZONE.10.10.in-addr.arpa | sudo tee /etc/bind/zones/db.$ZONE.10.10.in-addr.arpa
done 
curl ${REPO}main/Files/etc_bind_zones_db.kubernerdes.lab | sudo tee /etc/bind/zones/db.kubernerdes.lab
curl ${REPO}main/Files/etc_bind_zones_db.apps.kubernerdes.lab | sudo tee /etc/bind/zones/db.apps.kubernerdes.lab

# Validate all the zone files
cd /etc/bind/zones
named-checkzone kubernerdes.lab db.kubernerdes.lab
for FILE in `ls *arpa`; do named-checkzone $(echo $FILE | sed 's/db.//g'; ) $FILE; done
cd -

# Restart Named Service
sudo systemctl restart named.service

# Reset the host lookups (hopefully)
sudo systemctl restart systemd-resolved.service
sudo resolvectl flush-caches

sudo systemctl status named.service 

exit 0
