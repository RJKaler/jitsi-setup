#!/bin/bash -e

#NOTE: This is a helper script as an adjunct to the primary server install script included in this repository. 
#If this is placed on virtually any recent Ubuntu LTS release from today at 6.13.25, this will clone the repo containing this code and do 
#even more than the original code in the process 

#shellcheck disable=all

error() { echo "Error - abort!" && exit 1; }

if ! command -v git; then 
    sudo apt-get install git -y
else 
    echo "git already installed - proceeding"
fi


git clone https://github.com/RJKaler/jitsi-setup &&  
    sleep 1s &&
    look="$(find "$PWD" -type d -iname "*jitsi-setup*")" 
if [[ -d "$look" ]]; then 
    echo good
else 
    error
fi

pushd ./jitsi-setup || { error; }
sudo chmod +x ./server-install.sh || { error; }

./server-install.sh
