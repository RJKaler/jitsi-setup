#!/bin/bash

#UPLOADED FIRST ON 4.16.25. TESTED ON UBUNTU: Description:	Ubuntu 24.04.2 LTS


#TEMPORARY SHELLCHECK DISABLE
#shellcheck disable=all

#DEV GUIDE:
#https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/

error() { echo "error" && exit 1; }
#
#update() { sudo apt-get update && sudo apt upgrade -y || error; }

#update local host 
#initial update
#update
#
#sudo apt-get install apt-transport-https -y || error 
#sudo apt-add-repository universe || error 

#post package update
#update && echo "successfully updated a second time..."  

#NOTE: Everything above appears solid ... 

#change hostname for server 
read -rep "Pick a name for your server host: " name 

if [[ -n "$name" ]]; then 
    sudo hostnamectl set-hostname "$name" && echo "hostname set" || error 
else 
    echo "No changes made - proceeding..." 
    return
fi


