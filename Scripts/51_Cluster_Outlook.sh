#!/bin/bash

#     Purpose:  Basic commands to check cluster health
#        Date: 2024-07-02
#      Status:  Work in Progress | I anticipate adding more content
# Assumptions:
#        Todo:
#  References:
#       Notes: 

kubectl get events -A --sort-by=.lastTimestamp

exit 0
