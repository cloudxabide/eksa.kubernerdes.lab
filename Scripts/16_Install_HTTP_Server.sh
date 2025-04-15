#!/bin/bash

#     Purpose: deploy an HTTP/S Server (running on port 8080)
#        Date: 2024-07-01
#      Status: Work in Progress (moving to /var/www/eksa for EKS Anywhere) 
# Assumptions: You want to host your own images, and want to use port 8080 for the web service
#        Todo:
#              I need to have the webserver configured to provide web content via port 80 (for Harvester, etc..)
#              /var/www/eksa :8080
#              /var/www/html :80 

# Install the Apache2 packages
sudo apt install -y apache2 php libapache2-mod-php php-mysql php-yaml

# Configure Apache to listen to 8080 as well as 80
sudo sed -i -e 's/Listen 80/Listen 80\nListen 8080/g' /etc/apache2/ports.conf

# TODO: this needs testing
#  create separate EKSA configuration (and not modify the default)
sudo curl -o /etc/apache2/sites-available/eksa.conf https://raw.githubusercontent.com/cloudxabide/eksa.kubernerdes.lab/refs/heads/main/Files/etc_apache2_sites-enabled_eksa.conf
sudo curl -o /etc/apache2/sites-available/harvester.conf https://raw.githubusercontent.com/cloudxabide/eksa.kubernerdes.lab/refs/heads/main/Files/etc_apache2_sites-enabled_harvester.conf
sudo -E sh -c 'rm /etc/apache2/sites-enabled/000-default.conf; cd /etc/apache2/sites-available; a2ensite eksa.conf; a2ensite harvester.conf'

firewall_update() {
sudo ufw app list
sudo ufw allow in 'Apache'
sudo ufw status
sudo systemctl enable --now ufw
}

# Update the index page to be a dynamic version run in PHP
sudo curl -o /var/www/eksa/index.php ${REPO}main/Files/index.php
sudo curl -o /var/www/eksa/services.php ${REPO}main/Files/var_www_html_services.php
sudo curl -o /var/www/eksa/favicon.ico https://raw.githubusercontent.com/cloudxabide/kubernerdes.lab/refs/heads/main/Images/favicon.ico
sudo chown -R www-data:www-data /var/www
sudo chmod -R g+rwx /var/www
sudo systemctl enable apache2 --now
sudo systemctl restart apache2
exit 0

# NOTE:  you can now browse http://10.10.12.10:8080/
