#!/bin/bash

#     Purpose: Install Ansible
#        Date: 2024-07-02
#      Status: GTG | Complete/Done
# Assumptions:
#        Todo:

sudo apt-get install -y python-software-properties
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update

sudo apt-get install -y ansible
ansible --version

exit 0
