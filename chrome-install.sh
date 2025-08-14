#!/bin/bash -e 

update() { sudo apt-get update; }

error() { echo "Error. Abort!" && exit 1; }


#shellcheck disable=SC2015
chrome_install() {

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && 
sudo dpkg -i ./google-chrome-stable_current_amd64.deb


#update again ... 
update 

apt-get install google-chrome-stable -y


echo "holding package to protect from auto-removals" &&
sudo apt-mark hold google-chrome-stable &&
#Hide chrome warnings
{ sudo mkdir -vp /etc/opt/chrome/policies/managed || error; } &&
{  echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' | \
 sudo tee -a /etc/opt/chrome/policies/managed/managed_policies.json; } || error 
}

if chrome_install; then 
    echo -e "finished installing chrome stable.\nInstalling chromedriver next..." 
    update 
else 
    error 
fi   

