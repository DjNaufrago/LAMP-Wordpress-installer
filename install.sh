#!bin/bash

#
#       Author:   Reinaldo Moreno
#  Description:   Apache web server installer, PHP modules,
#                 MariaDB database, firewall configuration
#                 and Wordpress.
#           SO:   Ubuntu Server 22.04
# Architecture:   EC2 Amazon Web Service Instance
#

Yellow='\033[0;33m'       # Yellow
Color_Off='\033[0m'       # Reset

startinstall() {
  echo -e "${Yellow} * Starting installation... ${Color_Off}"
  touch log.txt
  echo "Unattended installation of LAMP server and" >> log.txt
  echo "WordPress Script - Reinaldo Moreno" >> log.txt
}

# Update repository and install latest packages.
updateupgrade() {
  echo "$(date "+%F - %T") - Update the list of repositories." >> log.txt
  apt-get -y -qq update
  echo "$(date "+%F - %T") - Installing latest packages." >> log.txt
  apt-get -y -qq upgrade
  echo "$(date "+%F - %T") - Installing pwgen password generator." >> log.txt
  apt-get install -qq pwgen
}
    
# Install apache web server.
installapache() {
	apt-get -qq install apache2
  echo "$(date "+%F - %T") - Installing Apache2." >> log.txt
}

# Install PHP modules.
installphp() {
  apt-get -qq install php libapache2-mod-php php-mysql \
  php-common php-cli php-common php-json php-opcache php-readline \
  php-mbstring php-gd php-dom php-zip php-curl
  echo "$(date "+%F - %T") - Installing PHP modules." >> log.txt
}

# Install MariaDB Server and generate key for root user.
# Remove anonymous users, remove remote access and delete test database.
installmariadb() {
  echo "$(date "+%F - %T") - Generating root key for MariaDB." >> log.txt
  DB_ROOT_PASS="$(pwgen -1 -s 16)"

  echo "$(date "+%F - %T") - Installing MariaDB." >> log.txt
  apt-get install -qq mariadb-server

  echo "$(date "+%F - %T") - Setting root password for MariaDB." >> log.txt
  mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
    'mysql_native_password', '$.authentication_string', \
    PASSWORD('$DB_ROOT_PASS')) WHERE User='root';"

  echo "$(date "+%F - %T") - Applying privileges to MariaDB root user." >> log.txt    
  mysql -e "FLUSH PRIVILEGES;"  

  echo "$(date "+%F - %T") - Deleting anonymous users in MariaDB." >> log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='';"
  echo "$(date "+%F - %T") - Removing remote access to databases." >> log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "$(date "+%F - %T") - Deleting test database." >> log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DROP DATABASE IF EXISTS test;"
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo "$(date "+%F - %T") - Applying changes." >> log.txt
  mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
}

# Generate database key, create user and database for wordpress.
configmariadbwp() {
  echo "$(date "+%F - %T") - Generating password for WordPress user." >> log.txt
  WP_DB_NAME="dbwordpress"
  WP_DB_USER="userwp"
  WP_DB_PASS="$(pwgen -1 -s 16)"

  echo "" >> log.txt
  echo "# ===== MARIADB AND WORDPRESS DETAILS AND PASSWORDS =====" >> log.txt
  echo "# =====" >> log.txt
  echo "# ===== MARIADB ROOT PASSWORD:        $DB_ROOT_PASS" >> log.txt
  echo "# =====" >> log.txt  
  echo "# ===== WORDPRESS DATABASE NAME:      $WP_DB_NAME" >> log.txt
  echo "# ===== WORDPRESS DATABASE USER:      $WP_DB_USER" >> log.txt
  echo "# ===== WORDPRESS DATABASE PASSWORD:  $WP_DB_PASS" >> log.txt
  echo "# =====" >> log.txt
  echo "# ============================================ ===========" >> log.txt
  echo "" >> log.txt

  echo "$(date "+%F - %T") - Creating database and user for WordPress." >> log.txt
  mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; \
    GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; \
    FLUSH PRIVILEGES"
}

# Download latest version of wordpress.
downloadinstallwp() {
  echo "$(date "+%F - %T") - Downloading the latest version of WordPress from $URLWP." >> log.txt
  URLWP="https://wordpress.org/latest.tar.gz"
  wget "$URL"

  # Unzip and move the contents of the directory to /var/www/html.
  # Set values to improve wordpress performance.

  echo "$(date "+%F - %T") - Decompressing file and moving the content." >> log.txt
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/; rm index.html /var/www/html

  echo "$(date "+%F - %T") - Setting permissions to the web directory to the user $USER." >> log.txt
  adduser $USER www-data \
  && chown -R $USER:www-data /var/www \
  && chmod 2775 /var/www \
  && find /var/www -type d -exec sudo chmod 2775 {} \; \
  && find /var/www -type f -exec sudo chmod 0664 {} \;

  echo "$(date "+%F - %T") - Adding an entry to the config index." >> log.txt
  sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

  echo "" >> /var/www/html/.htaccess  
  echo "php_value memory_limit 256M" >> /var/www/html/.htaccess
  echo "php_value upload_max_filesize 64M" >> /var/www/html/.htaccess
  echo "php_value post_max_size 64M" >> /var/www/html/.htaccess
  echo "php_value max_execution_time 300" >> /var/www/html/.htaccess
  echo "php_value max_input_time 1000" >> /var/www/html/.htaccess
  echo "" >> /var/www/html/wp-config.php
  echo "define( 'FS_METHOD', 'direct' );" >> /var/www/html/wp-config.php

  echo "$(date "+%F - %T") - Enabling configuration in apache2.conf." >> log.txt
  URLFILE="/etc/apache2/apache2.conf"
	NEWTEXT="AllowOverride All"
	LINENUMBER="$( (awk '/<Directory \/var\/www\/>/,/<\/Directory>/ {printf NR "  "; print}' \
    /home/ubuntu/apache2.conf | grep AllowOverride) | grep -Eo '[0-9]{1,3}' )"
  sed -i "${LINENUMBER}s/.*/\t&$NEWTEXT/" $URLFILE
}

# Set rules on the firewall to give access to ssh, http, https.
configfirewall() {
  echo "$(date "+%F - %T") - Setting firewall rules for ports 22, 80 and 443." >> log.txt
  ufw default deny incoming
  ufw allow ssh
  ufw allow http
  ufw allow https
  echo y | ufw enable
}

# Clean installation cache and files that are no longer needed.
finishclean() {
  echo "$(date "+%F - %T") - Deleting installation files that are no longer needed." >> log.txt
  rm latest.tar.gz
  rm -r wordpress/
  rm -rf /var/www/html/index.html

  echo "$(date "+%F - %T") - Clearing package cache." >> log.txt
  apt-get clean
  apt-get autoclean
}

startinstall
updateupgrade
installapache
installphp
installmariadb
configmariadbwp
downloadinstallwp
configfirewall
finishclean
systemctl reload apache2

echo -e "\n${Yellow} * Installation details in log.txt. DO NOT DELETE THIS FILE.${Color_Off}"
