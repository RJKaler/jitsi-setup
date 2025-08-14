#!/bin/bash -e 


#shellcheck disable=SC2015
chrome_install() {
sudo apt-get install google-chrome-stable -y &&
echo "holding package to protect from auto-removals" &&
sudo apt-mark hold google-chrome-stable &&
#Hide chrome warnings
{ sudo mkdir -vp /etc/opt/chrome/policies/managed || error; } &&
{ echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' \
>> /etc/opt/chrome/policies/managed/managed_policies.json; } || error 
}

if chrome_install; then 
    echo -e "finished installing chrome stable.\nInstalling chromedriver next..." 
    update 
else 
    error 
fi   

chrome_driver_install() {
# 1. Retrieve your installed Chrome major.minor.patch version.
CHROME_VER_FULL=$(dpkg -s google-chrome-stable \
  | awk '/^Version: /{print $2}')
CHROME_VER_MAJOR_MINOR_PATCH=$(echo "$CHROME_VER_FULL" | cut -d. -f1-3)

# 2. Base URL for Chrome for Testing API.
CFT_BASE="https://googlechromelabs.github.io/chrome-for-testing"

# 3. Fetch the known-good versions JSON and find the matching ChromeDriver.
CHROMEDRIVER_URL=$(curl -s "$CFT_BASE/known-good-versions-with-downloads.json" \
  | jq -r --arg VER "$CHROME_VER_MAJOR_MINOR_PATCH" \
      '.versions[].downloads.chromedriver?.[]? | select(.url | test($VER)) | .url' \
  | grep linux64 \
  | tail -1)

if [[ -z "$CHROMEDRIVER_URL" ]]; then
  echo "No matching ChromeDriver found for version $CHROME_VER_MAJOR_MINOR_PATCH"
  exit 1
fi

echo "Found ChromeDriver URL: $CHROMEDRIVER_URL"

# 4. Download and install it.
TMPDIR=$(mktemp -d)
wget -q -O "$TMPDIR/chromedriver-linux64.zip" "$CHROMEDRIVER_URL"
unzip -o "$TMPDIR/chromedriver-linux64.zip" -d "$TMPDIR"
sudo mv "$TMPDIR/chromedriver-linux64/chromedriver" /usr/local/bin/
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 755 /usr/local/bin/chromedriver

echo "ChromeDriver installed successfully at /usr/local/bin/chromedriver"
}

if chrome_driver_install; then 
    echo "Successfully installed Chrome driver..." 
else 
    error 
fi
}
if chrome_install; then 
    echo -e "finished installing chrome stable.\nInstalling chromedriver next..." 
    update 
else 
    error 
fi   

chrome_driver_install() {
# 1. Retrieve your installed Chrome major.minor.patch version.
CHROME_VER_FULL=$(dpkg -s google-chrome-stable \
  | awk '/^Version: /{print $2}')
CHROME_VER_MAJOR_MINOR_PATCH=$(echo "$CHROME_VER_FULL" | cut -d. -f1-3)

# 2. Base URL for Chrome for Testing API.
CFT_BASE="https://googlechromelabs.github.io/chrome-for-testing"

# 3. Fetch the known-good versions JSON and find the matching ChromeDriver.
CHROMEDRIVER_URL=$(curl -s "$CFT_BASE/known-good-versions-with-downloads.json" \
  | jq -r --arg VER "$CHROME_VER_MAJOR_MINOR_PATCH" \
      '.versions[].downloads.chromedriver?.[]? | select(.url | test($VER)) | .url' \
  | grep linux64 \
  | tail -1)

if [[ -z "$CHROMEDRIVER_URL" ]]; then
  echo "No matching ChromeDriver found for version $CHROME_VER_MAJOR_MINOR_PATCH"
  exit 1
fi

echo "Found ChromeDriver URL: $CHROMEDRIVER_URL"

# 4. Download and install it.
TMPDIR=$(mktemp -d)
wget -q -O "$TMPDIR/chromedriver-linux64.zip" "$CHROMEDRIVER_URL"
unzip -o "$TMPDIR/chromedriver-linux64.zip" -d "$TMPDIR"
sudo mv "$TMPDIR/chromedriver-linux64/chromedriver" /usr/local/bin/
sudo chown root:root /usr/local/bin/chromedriver
sudo chmod 755 /usr/local/bin/chromedriver

echo "ChromeDriver installed successfully at /usr/local/bin/chromedriver"
}

if chrome_driver_install; then 
    echo "Successfully installed Chrome driver..." 
else 
    error 
fi

