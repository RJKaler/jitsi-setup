#!/bin/bash -e

#This should suffice for a single deployment Jitsi Meet server - but I would not go over two video bridges with this. 

update() { sudo apt-get update; }
error() { echo "Error. Abort!" && exit 1; }

logdir="$HOME/jitsi-logs"


if [[ ! -d "$logdir" ]]; then
     mkdir -vp "$logdir" || error
     echo "finished creating directory for log file"
fi


log_file="$logdir/server_install.log"


#GUIDE: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/

#Required packages and repository updates (GUIDE)

if ! command -v curl; then
	sudo apt-get install curl -y || { echo "error!" && exit 1; }
fi

{

require_proc() {
    echo "refreshing package list"
    #shellcheck disable=SC2015
    update &&
        # Ensure support for apt repositories served via HTTPS
            sudo apt-get install apt-transport-https -y || { error; } &&
                yes y | sudo apt-add-repository universe || error
            echo "installing Socat (for SOcket CAT) for stand-alone server deployment..." 
            sudo apt-get install socat -y || error
            }

            echo "installing basic packages for server..."

            if require_proc; then
                echo "successfully installed packages and updated package list"
            else
                error
            fi

#SET UP DNS HERE
#=================================

#read -rep "Optional: Create a DNS entry for easy server access. Ex: meet.domain.org  (y|n): " ans

#changehost() { sudo hostnamectl set-hostname "$@"; }
#
#if [[ "$ans" =~ ^(y|Y|yes|Yes)$ ]]; then
#    while :
#    do
#        read -rep "OK - enter a hostname for your server: " servername
#        if [[ -z "$servername" ]]; then
#            echo "Error - no value was entered."
#        else
#            echo "Changing host name to $servername"
#            if changehost "$servername"; then
#                echo "Success!"
#                break
#            else
#                error
#            fi
#        fi
#    done
#else
#    echo "OK - skipping..."
#fi
#

#Add the Prosody package repository

#function to install Prosody dependencies
prosody_proc() {
    sudo curl -sL https://prosody.im/files/prosody-debian-packages.key -o  /etc/apt/keyrings/prosody-debian-packages.key &&
        echo "deb [signed-by=/etc/apt/keyrings/prosody-debian-packages.key] http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/prosody-debian-packages.list &&
        sudo apt-get install lua5.2 -y && echo "installed lua5.2"
    }


    echo "Installing prosody dependencies..."
    if prosody_proc; then
        echo "Successfully added prosody sources"
        echo "updating all packages..."
        update || error
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
    echo "Successfully added prosody sources"
    echo "updating all packages..."
    update || error
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
    update || error
fi

echo "Successfully completed pre-installation steps."
echo "IMPORTANT! Type or paste: sudo apt install jitsi-meet -y"
echo "Follow on-screen prompts to complete installation." 

echo "Need more info? Log file: $log_file."

} | tee -a "$log_file"
