#!/bin/bash -e

####################################################################
# install-jitsi-server.sh
#
# Description:
# Jitsi Meet Deployment Script
#
# History:
# 2025-06-07 Created - Richard Kaler
#
# License:
# GNU GPL v3.0 or later
####################################################################

update() { sudo apt-get update; }
error() { echo "Error. Abort!" && exit 1; }

log_file="$PWD/server_install.log"

{
# Update system
update

if ! command -v curl &>/dev/null; then
    sudo apt-get install curl -y || { echo "error!" && exit 1; }
    update
fi

# Install Apache
apache_install() {
    sudo apt-get install apache2 -y || error
    update
}
apache_install

# Install basic dependencies
require_proc() {
    echo "Refreshing package list..."
    update &&
    sudo apt-get install apt-transport-https -y || error
    sudo apt-add-repository universe -y || error
    echo "Installing Socat..."
    sudo apt-get install socat -y || error
}
echo "Installing basic packages for server..."
if require_proc; then
    echo "Successfully installed packages and updated package list"
    update
else
    error
fi

# Add Jitsi repo
jitsi_proc() {
    curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
}
echo "Installing Jitsi dependencies..."
if jitsi_proc; then
    echo "Successfully added Jitsi sources"
    update
else
    error
fi

# Configure UFW
sudo ufw enable || error
ufw_proc() {
    sudo ufw allow 80/tcp || error
    sudo ufw allow 443/tcp || error
    sudo ufw allow 10000/udp || error
    sudo ufw allow 22/tcp || error
    sudo ufw allow 3478/udp || error
    sudo ufw allow 5349/tcp || error
}
if ufw_proc; then
    echo "Successfully modified firewall"
    update
else
    error
fi

# Install ffmpeg
echo "Installing ffmpeg..."
if sudo apt-get install ffmpeg -y; then
    echo "Successfully installed ffmpeg"
    update
else
    error
fi

# Install Chromium and configure Jibri for it
chromium_proc() {
CONFIG="/etc/jitsi/jibri/jibri.conf"
CHROMIUM_PATH="/usr/bin/chromium-browser"

if ! command -v chromium-browser &>/dev/null; then
    echo "[INFO] Installing Chromium..."
    sudo apt update && sudo apt install -y chromium-browser chromium-chromedriver
fi

# Create or update jibri.conf for Chromium
if [ ! -f "$CONFIG" ]; then
    echo "[INFO] Creating $CONFIG"
    sudo tee "$CONFIG" > /dev/null <<EOF
jibri {
  chrome {
    executable-path = "$CHROMIUM_PATH"
    flags = [
      "--use-fake-ui-for-media-stream",
      "--start-maximized",
      "--kiosk",
      "--enabled",
      "--disable-infobars",
      "--autoplay-policy=no-user-gesture-required",
      "--no-sandbox",
      "--disable-dev-shm-usage"
    ]
  }
}
EOF
else
    echo "[INFO] Updating $CONFIG for Chromium..."
    if grep -q "chrome" "$CONFIG"; then
        sudo sed -i "s|executable-path = .*|executable-path = \"$CHROMIUM_PATH\"|" "$CONFIG"
    else
        sudo tee -a "$CONFIG" > /dev/null <<EOF

chrome {
  executable-path = "$CHROMIUM_PATH"
  flags = [
    "--use-fake-ui-for-media-stream",
    "--start-maximized",
    "--kiosk",
    "--enabled",
    "--disable-infobars",
    "--autoplay-policy=no-user-gesture-required",
    "--no-sandbox",
    "--disable-dev-shm-usage"
  ]
}
EOF
    fi
fi

# Disable Chromium security warnings
sudo mkdir -vp /etc/chromium/policies/managed
echo '{ "CommandLineFlagSecurityWarningsEnabled": false }' | sudo tee /etc/chromium/policies/managed/managed_policies.json
update
}
if chromium_proc; then
    echo "Successfully installed and configured Chromium"
else
    error
fi

# Install Jibri and configure systemd + XMPP
jibri_proc() {
SERVICE_FILE="/etc/systemd/system/jibri.service"
CONFIG="/etc/jitsi/jibri/jibri.conf"

sudo apt-get install jibri -y || error

# Patch systemd to use Chromium instead of Google Chrome
if [ -f "$SERVICE_FILE" ]; then
    echo "[INFO] Patching Jibri systemd unit to use Chromium..."
    sudo sed -i 's|/usr/bin/google-chrome|/usr/bin/chromium-browser|' "$SERVICE_FILE"
    sudo systemctl daemon-reload
fi

# Change these defaults or make them user inputs
JITSI_DOMAIN="yourdomain.com"
XMPP_SERVER_IP="1.2.3.4"
JIBRI_AUTH_USER="jibri"
JIBRI_AUTH_PASS="jibriauthpass"
RECORDER_USER="recorder"
RECORDER_PASS="jibrirecorderpass"

echo "[INFO] Configuring Jibri XMPP environment..."
if ! grep -q "api" "$CONFIG"; then
sudo tee -a "$CONFIG" > /dev/null <<EOF
api {
  xmpp {
    environments = [
      {
        name = "$JITSI_DOMAIN"
        xmpp-server-hosts = ["$XMPP_SERVER_IP"]
        xmpp-domain = "$JITSI_DOMAIN"
        control-login {
          domain = "auth.$JITSI_DOMAIN"
          username = "$JIBRI_AUTH_USER"
          password = "$JIBRI_AUTH_PASS"
          port = 5222
        }
        control-muc {
          domain = "internal.auth.$JITSI_DOMAIN"
          room-name = "JibriBrewery"
          nickname = "jibri-\${XMPP_SERVER_IP//./-}"
        }
        call-login {
          domain = "recorder.$JITSI_DOMAIN"
          username = "$RECORDER_USER"
          password = "$RECORDER_PASS"
        }
        strip-from-room-domain = "conference."
        trust-all-xmpp-certs = true
        usage-timeout = 0
      }
    ]
  }
}
EOF
else
    echo "[INFO] XMPP config already exists, skipping..."
fi

sudo systemctl restart jibri
}
if jibri_proc; then
    echo "Successfully installed and configured Jibri"
else
    error
fi

echo "Successfully completed pre-installation steps."
echo "-------------------------------------------------------------------------"
echo "IMPORTANT! Type or paste:"
echo ""
echo "   sudo apt install jitsi-meet -y"
echo ""
echo "- Follow on-screen prompts to complete installation."
echo "-------------------------------------------------------------------------"
echo "MANDATORY REBOOT AFTER COMPLETION"
echo "-------------------------------------------------------------------------"
echo "Need more info? Log file: $log_file."

} | tee -a "$log_file"
