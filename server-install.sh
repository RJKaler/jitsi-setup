#!/bin/bash -e

####################################################################
# install-jitsi-server.sh
#
# Description:
#   Jitsi Meet Deployment Script
#
# History:
# 2025-06-07 Created - Richard Kaler
#
#
# This script is licensed under the GNU General Public License v3.0 or later.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see .
#
# Copyright (c) 2025 Runchero Federation / P.I.S.A.
####################################################################


#This should suffice for a single deployment Jitsi Meet server - but I would not go over two video bridges with this.

update() { sudo apt-get update --allow-insecure-repositories; }
error() { echo "Error. Abort!" && exit 1; }

#logdir="$HOME/jitsi-logs"


log_file="$PWD/server_install.log"


#GUIDE: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/

{

if ! command -v curl; then
	sudo apt-get install curl -y || { echo "error!" && exit 1; }
fi


#install apache
apache_install() {
	update
	sudo apt-get install apache2 -y || error
}

apache_install


require_proc() {
    echo "refreshing package list"
    #shellcheck disable=SC2015
    update &&
        # Ensure support for apt repositories served via HTTPS
            sudo apt-get install apt-transport-https -y || { error; } &&
                yes y | sudo apt-add-repository universe -y || { error; } &&
            echo "installing Socat (for Socket CAT) for stand-alone server deployment..."
            sudo apt-get install socat -y || error
            }

            echo "installing basic packages for server..."

            if require_proc; then
                echo "successfully installed packages and updated package list"
            else
                error
            fi


#Add Jitsi packages
jitsi_proc() {
    curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
}

    echo "Installing jitsi dependencies..."


if jitsi_proc; then
    echo "Successfully added prosody sources"
    echo "updating all packages..."
    update
else
    error
fi

#configure ufw

sudo ufw enable || error

#shellcheck disable=SC2015

ufw_proc() {
sudo ufw allow 80/tcp || { error; }
sudo ufw allow 443/tcp || { error; }
sudo ufw allow 10000/udp || { error; }
sudo ufw allow 22/tcp || { error; }
sudo ufw allow 3478/udp || { error; }
sudo ufw allow 5349/tcp || { error; }
}


if ufw_proc; then
    echo "Successfully modified firewall for server"
    echo "updating all packages..."
    update
else
    error
fi

echo "Successfully completed pre-installation steps."
echo "-------------------------------------------------------------------------"
echo "IMPORTANT! Type or paste: "
echo "-------------------------------------------------------------------------"
echo ""
echo "   sudo apt install jitsi-meet -y"
echo ""
echo " - Follow on-screen prompts to complete installation."
echo "-------------------------------------------------------------------------"
echo "                        MANDATORY REBOOT PLEASE                          "
echo "-------------------------------------------------------------------------"

echo "Need more info? Log file: $log_file."

} | tee -a "$log_file"
