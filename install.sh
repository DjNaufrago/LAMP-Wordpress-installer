#!bin/bash

#
#       Author:   Reinaldo Moreno
#  Description:   Apache web server installer, PHP modules,
#                 MariaDB database, firewall configuration
#                 and Wordpress.
#           SO:   Ubuntu Server 22.04
# Architecture:   EC2 Amazon Web Service Instance
#

startinstall() {
  Yellow='\033[0;33m'       # Yellow
  Color_Off='\033[0m'       # Reset

  echo -e "${Yellow} * Starting installation... ${Color_Off}"
  touch log.txt
  echo "Unattended installation of LAMP server and" | tee -a log.txt
  echo "WordPress Script - Reinaldo Moreno" | tee -a log.txt
}

# Update repository and install latest packages.
updateupgrade() {
  echo "$(date "+%F - %T") - Update the list of repositories." | tee -a log.txt
  apt-get -y -qq update
  echo "$(date "+%F - %T") - Installing latest packages." | tee -a log.txt
  apt-get -y -qq upgrade
  echo "$(date "+%F - %T") - Installing pwgen password generator." | tee -a log.txt
  apt-get install -qq pwgen
}
    
# Install apache web server.
installapache() {
	apt-get -qq install apache2
  echo "$(date "+%F - %T") - Installing Apache2." | tee -a log.txt
}

# Install PHP modules.
installphp() {
  apt-get -qq install php libapache2-mod-php php-mysql \
  php-common php-cli php-common php-json php-opcache php-readline \
  php-mbstring php-gd php-dom php-zip php-curl
  echo "$(date "+%F - %T") - Installing PHP modules." | tee -a log.txt
}

# Install MariaDB Server and generate key for root user.
# Remove anonymous users, remove remote access and delete test database.
installmariadb() {
  echo "$(date "+%F - %T") - Generating root key for MariaDB." | tee -a log.txt
  DB_ROOT_PASS="$(pwgen -1 -s 16)"

  echo "$(date "+%F - %T") - Installing MariaDB." | tee -a log.txt
  apt-get install -qq mariadb-server

  echo "$(date "+%F - %T") - Setting root password for MariaDB." | tee -a log.txt
  mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
    'mysql_native_password', '$.authentication_string', \
    PASSWORD('$DB_ROOT_PASS')) WHERE User='root';"

  echo "$(date "+%F - %T") - Applying privileges to MariaDB root user." | tee -a log.txt    
  mysql -e "FLUSH PRIVILEGES;"  

  echo "$(date "+%F - %T") - Deleting anonymous users in MariaDB." | tee -a log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='';"
  echo "$(date "+%F - %T") - Removing remote access to databases." | tee -a log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "$(date "+%F - %T") - Deleting test database." | tee -a log.txt
  mysql -u root -p$DB_ROOT_PASS -e "DROP DATABASE IF EXISTS test;"
  mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo "$(date "+%F - %T") - Applying changes." | tee -a log.txt
  mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
}

# Generate database key, create user and database for wordpress.
configmariadbwp() {
  echo "$(date "+%F - %T") - Generating password for WordPress user." | tee -a log.txt
  WP_DB_NAME="dbwordpress"
  WP_DB_USER="userwp"
  WP_DB_PASS="$(pwgen -1 -s 16)"

  echo -e '\n' >> log.txt
  echo '# ===== MARIADB AND WORDPRESS DETAILS AND PASSWORDS =====' | tee -a log.txt
  echo '# =====' | tee -a log.txt
  echo "# ===== MARIADB ROOT PASSWORD:        $DB_ROOT_PASS" | tee -a log.txt
  echo '# =====' | tee -a log.txt  
  echo "# ===== WORDPRESS DATABASE NAME:      $WP_DB_NAME" | tee -a log.txt
  echo "# ===== WORDPRESS DATABASE USER:      $WP_DB_USER" | tee -a log.txt
  echo "# ===== WORDPRESS DATABASE PASSWORD:  $WP_DB_PASS" | tee -a log.txt
  echo '# =====' | tee -a log.txt
  echo '# =======================================================' | tee -a log.txt
  echo -e '\n' >> log.txt

  echo "$(date "+%F - %T") - Creating database and user for WordPress." | tee -a log.txt
  mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; \
    GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; \
    FLUSH PRIVILEGES"
}

# Download latest version of wordpress.
# Unzip and move the contents of the directory to /var/www/html.
downloadinstallwp() {
  URLWP="https://wordpress.org/latest.tar.gz"
  echo "$(date "+%F - %T") - Downloading the latest version of WordPress from $URLWP." | tee -a log.txt
  wget "$URLWP"
  echo "$(date "+%F - %T") - Decompressing file and moving the content." | tee -a log.txt
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/
}

webfolder() {
  echo "$(date "+%F - %T") - Setting permissions to the web directory to the user $USER." | tee -a log.txt
  adduser $USER www-data \
  && chown -R $USER:www-data /var/www \
  && chmod 2775 /var/www \
  && find /var/www -type d -exec sudo chmod 2775 {} \; \
  && find /var/www -type f -exec sudo chmod 0664 {} \;
}

# Enabling settings for WordPress
configwp() {
  cp /etc/apache2/mods-enabled/dir.conf /etc/apache2/mods-enabled/dir.conf.bk
  echo "$(date "+%F - %T") - Adding an entry to the config index." | tee -a log.txt
  sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

  cp /var/www/html/.htaccess /var/www/html/.htaccess.bk
  echo -e '\n' >> /var/www/html/.htaccess  
  echo 'php_value memory_limit 256M' >> /var/www/html/.htaccess
  echo 'php_value upload_max_filesize 64M' >> /var/www/html/.htaccess
  echo 'php_value post_max_size 64M' >> /var/www/html/.htaccess
  echo 'php_value max_execution_time 300' >> /var/www/html/.htaccess
  echo 'php_value max_input_time 1000' >> /var/www/html/.htaccess
  
  cp /var/www/html/wp-config.php /var/www/html/wp-config.php.bk
  echo -e '\n' >> /var/www/html/wp-config.php
  echo 'define( 'FS_METHOD', 'direct' );' >> /var/www/html/wp-config.php

  echo "$(date "+%F - %T") - Enabling configuration in apache2.conf." | tee -a log.txt
  cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bk
  URLFILE="/etc/apache2/apache2.conf"
	NEWTEXT="         AllowOverride All"
	LINENUMBER="$( (awk '/<Directory \/var\/www\/>/,/<\/Directory>/ {printf NR "  "; print}' \
    $URLFILE | grep AllowOverride) | grep -Eo '[0-9]{1,3}' )"
  sed -i "${LINENUMBER}s/.*/$NEWTEXT/" $URLFILE

  echo '=== Copies of the original configuration files were created:' | tee -a log.txt
  echo '=== - /etc/apache2/mods-enabled/dir.conf.bk' | tee -a log.txt
  echo '=== - /var/www/html/.htaccess.bk' | tee -a log.txt
  echo '=== - /var/www/html/wp-config.php.bk' | tee -a log.txt
  echo '=== - /etc/apache2/apache2.conf.bk' | tee -a log.txt
}

# Set rules on the firewall to give access to ssh, http, https.
configfirewall() {
  echo "$(date "+%F - %T") - Setting firewall rules for ports 22, 80 and 443." | tee -a log.txt
  ufw default deny incoming
  ufw allow ssh
  ufw allow http
  ufw allow https
  echo y | ufw enable
}

# Clean installation cache and files that are no longer needed.
finishclean() {
  echo "$(date "+%F - %T") - Deleting installation files that are no longer needed." | tee -a log.txt
  rm latest.tar.gz
  rm -d wordpress/
  rm /var/www/html/index.html

  echo "$(date "+%F - %T") - Clearing package cache." | tee -a log.txt
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
webfolder
configwp
configfirewall
finishclean
systemctl reload apache2

echo -e "\n${Yellow} * Installation details in log.txt. DO NOT DELETE THIS FILE.${Color_Off}"