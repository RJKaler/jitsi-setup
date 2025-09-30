#!/bin/bash

#shellcheck disable=all

error() { echo "error" && exit 1; }

wget https://storage.googleapis.com/chrome-for-testing-public/140.0.7339.207/linux64/chrome-linux64.zip || error

unzip -e ./chrome-linux64.zip || error

pushd ./chrome-linux64 &>/dev/null || error

sudo mkdir -v /opt/chromedriver || error

sudo mv -v ./chrome /opt/chromedriver/ || error

newpath="/opt/chromedriver/chrome"

sudo ln -sf "$newpath" /usr/local/bin/chrome || error

sudo chmod +x "$newpath" || error
