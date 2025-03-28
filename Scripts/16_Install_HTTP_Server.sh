#!/bin/bash

#     Purpose: deploy an HTTP/S Server (running on port 8080)
#        Date: 2024-07-01
#      Status: GTG
# Assumptions: You want to host your own images, and want to use port 8080 for the web service
#        Todo:

# Install the Apache2 packages
sudo apt install -y apache2 php libapache2-mod-php php-mysql

# Change the port apache2 will listen on
sudo sed -i -e 's/80/8080/g' /etc/apache2/ports.conf
sudo sed -i -e 's/80/8080/g' /etc/apache2/sites-enabled/000-default.conf

firewall_update() {
sudo ufw app list
sudo ufw allow in 'Apache'
sudo ufw status
sudo systemctl enable --now ufw
}

# Update the index page to be a dynamic version run in PHP
sudo curl -o /var/www/html/index.php ${REPO}main/Files/index.php
sudo curl -o /var/www/html/services.php ${REPO}main/Files/var_www_html_services.php
sudo curl -o /var/www/html/favicon.ico https://raw.githubusercontent.com/cloudxabide/kubernerdes.lab/refs/heads/main/Images/favicon.ico
sudo chown -R www-data:www-data /var/www
sudo chmod -R g+rwx /var/www
sudo systemctl enable apache2 --now
sudo systemctl restart apache2
exit 0

# NOTE:  you can now browse http://10.10.12.10:8080/


