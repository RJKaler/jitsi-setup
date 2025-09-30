#!/bin/bash

#shellcheck disable=all

error() { echo "error" && exit 1; }

wget https://storage.googleapis.com/chrome-for-testing-public/140.0.7339.207/linux64/chrome-linux64.zip

unzip -e ./chrome-linux64.zip  

pushd ./chrome-linux64 &>/dev/null 

sudo mkdir -v /opt/chromedriver | error 

sudo mv -vt /opt/chromedriver ./chrome

newpath="/opt/chromedriver/chrome"

sudo ln "$newpath" /usr/local/bin/



