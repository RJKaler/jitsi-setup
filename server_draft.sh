#!/bin/bash -e 

##shellcheck disable=all

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


#if [[ ! -d "$logdir" ]]; then
#     mkdir -vp "$logdir" || error
#     echo "finished creating directory for log file"
#fi


log_file="$PWD/server_install.log"


#GUIDE: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/

#Required packages and repository updates (GUIDE)
#


{
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

if jitsi_proc || error; then
    echo "updating all packages..."
    update || error
else
    error
fi




}

if prosody_proc || error; then 
    echo "succesfully installed prosody" 
fi


#update again 
update

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
    update || error
fi



chrome_install() {
apt-get -y install wget curl gnupg jq unzip  &&
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg &&
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list 

#update repositories 
update || error 

sudo apt-get -y install google-chrome-stable &&
sudo apt-mark hold google-chrome-stable  &&

mkdir -p /etc/opt/chrome/policies/managed &&
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' >> \
/etc/opt/chrome/policies/managed/managed_policies.json


curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'

echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

}

#check for chrome and install if needed

setup_chrome() {
CHROME_VER=$(dpkg -s google-chrome-stable | grep -E  "^Version" | cut -d " " -f2 | cut -d. -f1-3)
CHROMELAB_LINK="https://googlechromelabs.github.io/chrome-for-testing"
CHROMEDRIVER_LINK=$(curl -s $CHROMELAB_LINK/known-good-versions-with-downloads.json | jq -r ".versions[].downloads.chromedriver | select(. != null) | .[].url" | grep linux64 | grep "$CHROME_VER" | tail -1)
wget -O /tmp/chromedriver-linux64.zip "$CHROMEDRIVER_LINK"
}

sudo rm -rv /tmp/chromedriver-linux64 &&
unzip -o /tmp/chromedriver-linux64.zip -d /tmp &&
mv -vt /usr/local/bin/  /tmp/chromedriver-linux64/chromedriver  &&
sudo chown root:root /usr/local/bin/chromedriver &&
sudo chmod 755 /usr/local/bin/chromedriver

echo "checking for google chrome..." 

if command -v google-chrome; then 
    echo "chrome is already installed. Skipping..."
else 
    setup_chrome || error 
fi


jibri_install() {
 sudo add-apt-repository ppa:mc3man/trusty-media || error 
{ sudo apt-get install ffmpeg -y; }  || { error; }
{ sudo apt-get install jibri -y; } || { error; }

#set up user groups 
sudo usermod -aG adm,audio,video,plugdev jibri
#Install prosody as xmpp server 

prosody_proc() {
    #source: https://github.com/jitsi/jibri
    sudo curl -sL https://prosody.im/files/prosody-debian-packages.key -o /usr/share/keyrings/prosody-debian-packages.key &&
echo "deb [signed-by=/usr/share/keyrings/prosody-debian-packages.key] http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/prosody-debian-packages.list &&
sudo apt-get install lua5.2 -y 
}
#Modifying MUC component entry 

prosody_proc

echo -e '\n-- internal muc component, meant to enable pools of jibri and jigasi clients
Component "internal.auth.yourdomain.com" "muc"
    modules_enabled = {
      "ping";
    }
    -- storage should be "none" for prosody 0.10 and "memory" for prosody 0.11
    storage = "memory"
    muc_room_cache_size = 1000' | sudo tee -a /etc/prosody/prosody.cfg.lua && 
    echo "finished configuring prosody" 

jicofo_proc() {
echo -e '\njicofo {
  ...
  jibri {
    brewery-jid = "JibriBrewery@internal.auth.yourdomain.com"
    pending-timeout = 90 seconds
  }
  ...
}' | sudo tee -a /etc/jitsi/jicofo/jicofo.conf

#create virtual host entry

echo -e '\nVirtualHost "recorder.yourdomain.com"
  modules_enabled = {
    "ping";
  }
  authentication = "internal_hashed"' | sudo tee -a /etc/prosody/prosody.cfg.lua

#Account setup 

prosodyctl register jibri auth.yourdomain.com jibriauthpass || error 
prosodyctl register recorder recorder.yourdomain.com jibrirecorderpass || error 


#restarting jifco daemon 
echo "restarting jifco..." 

{ sudo systemctl stop jifco || error; }  && 
sleep 4s 
sudo systemctl start jifco || error 


} 
jicofo_proc 

jibri_config() {
while read -rep "Please enter your domain name to configure jibri " jibri_domain
do
    if [[ -z "$jibri_domain" ]]; then 
        echo "Error - missing something? Please try again..." 
        continue 
    fi
    break
done

domain_config_name="$(find /etc/jitsi/meet/ -iname "*js")"

printf "\n// recording
config.recordingService = {
  enabled: true,
  sharingEnabled: true,
  hideStorageWarning: false,
};

// liveStreaming
config.liveStreaming = {
  enabled: true,
};

jibri_congi

config.hiddenDomain = \"%s\";\n" "$jibri_domain" | sudo tee /etc/jitsi/meet/"$domain_config_name"; }

jibri_config

}


#OPTIONAL INSTALL: Jibri 
read -rep "Install jibri for video recordings? (y|n):" option

if [[ "$option" =~ ^(y|yes|Yes|Y)$ ]]; then 
    echo "OK - starting install..." 
    jibri_install || error 
else 
   return   
fi

echo "configuring jitsi for conference calls" 
#for conference calls



echo "modifying then restarting jicofo..." 

if jicofo_proc || error; then 
    echo "successfully modifed jicofo config" 
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
