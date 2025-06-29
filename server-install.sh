#!/bin/bash -e

##shellcheck disable=all

#Source: https://cwiki.apache.org/confluence/display/openmeetings/tutorials+for+installing+openmeetings+and+tools?preview=/27838216/334761243/Installation%20OpenMeetings%208.0.0%20on%20Ubuntu%2024.04%20lts.pdf
 
#log_file="$PWD/server_install.log"

#For repeated updates
update() { sudo apt-get update && sudo apt-get upgrade -y; }
#Abort at error 
error() { echo "Error. Abort!" && exit 1; }

#requirements: java, nano, libre office, ImageMagick, Sox, ffmpeg, MariaDB

#update before installing packages 
echo "updating system. Preparing for install..." 
update

echo "installing nano..." 

if sudo apt-get install nano -y || error; then 
    echo "successfully installed nano" 
fi

echo "installing java components..."  

if sudo apt-get install openjdk-21-jre openjdk-21-jre-headless -y || error; then 
    echo "successfully installed java packages" 
fi


libre_install() {
#Install libreoffice ppa 
yes y | sudo add-apt-repository ppa:libreoffice/ppa &&
echo "succcessfully added libre office repository"
Install libre office 
sudo apt-get install libreoffice -y  && 
echo "successfully installed libre office packages"
}

echo "installing libre office components..." 

if libre_install || error; then 
   echo "finished installing libre office" 
fi 

echo "installing imagemagick..." 

if sudo apt-get install imagemagick libjpeg62 zlib1g-dev -y || error; then 
   echo "successfully installed imagemagick" 
fi 

echo "installing sox for audio..." 

if sudo apt-get install sox -y || error; then 
    echo "finished installing sox" 
fi


echo "installing ffmpeg, vlc  and curl..." 

if sudo apt-get install ffmpeg vlc curl -y || error; then 
    echo "successfully installed ffmpeg and curl" 
fi

echo "installing MariaDB database server..." 

if sudo apt-get install mariadb-server -y || error; then 
    echo "server installed - starting daemon..." 
    if sudo systemctl enable --now mariadb; then
       echo "successfully started server daemon"
   else 
       error 
    fi
fi

echo "Configuring MariaDB database" 
echo "================================================================="
while : 
do
    read -resp "Create password for database root user (please keep note of password): " password1
    read -resp "Confirm password: " password2
    if [ "$password1" = "$password2" ]; then
        db_password="$password1"
        echo "Passwords match. Success!" 
        break 
    else
        echo "Passwords do not match. Please try again."
    fi
done

echo "Now applying password to database" 

#set password for mysql 
if sudo mysqladmin -u root password "$db_password" || error; then 
    echo "successfully set root password" 
fi


echo "==> A database has been installed but the setup is incomplete." 
echo "==> In order for OpenMeetings to work, the database setup process must be completed."
echo "==> You can continue setting up the database or exit this program now."
echo "==> Do you want to continue? (y|n): " 
read -rep "==> " ans

if [[ "$ans" =~ ^(y|Y|yes|Yes)$ ]]; then 
    echo "OK - proceeding" 
else 
    echo "OK - exiting script now" 
    exit 0
fi

echo -e "\n======> Please follow the instructions below <======

1.) Log into database (WITHOUT sudo) using the password you just created. Type: mysql -u root -p 

2.) Enter the following once logged in: 

MariaDB [(none)]> CREATE DATABASE open800 DEFAULT CHARACTER SET 'utf8';

(IMPORTANT: We are creating a new password. Unless the only user is root, for optimal security, use a different password below. Please make note of your password below as it will be used later. Note, \"[username]\" below can be an already existing user. If that user does not already exist elsewhere on the system, it will be created here.) 

MariaDB [(none)]> GRANT ALL PRIVILEGES ON open800.* TO '[username]'@'localhost' IDENTIFIED BY '1a2B3c4D' WITH GRANT OPTION;

MariaDB [(none)]> quit
(At this point, we will have exited the database to proceed with the remaining installation steps.)
===================================================\n"

read -rep "You can proceed once the steps above are finished.
Ready to proceed (y|n): " ans

if [[ "$ans" =~ ^(y|Y|yes|Yes)$ ]]; then 
    echo "OK - proceeding" 
else 
    echo "OK - exiting script now" 
    exit 0
fi

