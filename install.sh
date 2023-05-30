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

# Add repository, update list and install necessary packages.
echo -e "${Yellow} * Installing necessary packages... ${Color_Off}"
touch log.txt
echo "$(date "+%F - %T) - Creating log file." >> log.txt
add-apt-repository -yu universe
echo "$(date "+%F - %T) - Adding UNIVERSE repository and updating package list." >> log.txt
apt-get install -yq dialog pwgen
echo "$(date "+%F - %T) - Installing dialog and pwgen." >> log.txt

DTITLE="LAMP Server Installation for WordPress"
DRESULT="Action Completed"

# Install latest packages.
updatepack() {
  apt-get upgrade -y 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Updating Packages" \
  	--progressbox 16 60
    echo "$(date "+%F - %T) - Installing latest packages." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Updating Packages" \
      --msgbox "$DRESULT" 10 70 
  fi
}

# Install apache web server.
installapache() {
	apt-get install -qq apache2 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Installing Apachee" \
  	--progressbox 16 70
    echo "$(date "+%F - %T) - Installing Apache2." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Installing Apache" \
      --msgbox "$DRESULT" 10 70 
  fi
}

# Install PHP modules.
installphp() {
  apt-get install -qq sudo apt install php libapache2-mod-php php-mysql \
  php-common php-cli php-common php-json php-opcache php-readline \
  php-mbstring php-gd php-dom php-zip php-curl 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Installing PHP modules" \
  	--progressbox 16 70
    echo "$(date "+%F - %T) - Installing PHP modules." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Installing PHP modules" \
      --msgbox "$DRESULT" 10 70 
  fi
}

# Install MariaDB Server and generate key for root user.
# Remove anonymous users, remove remote access and delete test database.
installmariadb() {
  DB_ROOT_PASS="$(pwgen -1 -s 16)"
  echo "$(date "+%F - %T) - Generating root key for MariaDB = $DB_ROOT_PASS" >> log.txt
  apt-get install -qq mariadb-server 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Installing MariaDB" \
  	--progressbox 16 60
    echo "$(date "+%F - %T) - Installing MariaDB." >> log.txt
  if [ "$?" = 0 ]
  then
    mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
      'mysql_native_password', '$.authentication_string', \
      PASSWORD('$DB_ROOT_PASS')) WHERE User='root';" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Installing MariaDB" \
      --msgbox "Configuring database and user..." 10 70 
      echo "$(date "+%F - %T) - Setting admin permissions." >> log.txt
    
    mysql -e "FLUSH PRIVILEGES;" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Installing MariaDB" \
      --msgbox "applying privileges." 10 70    
    
    mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='';\
      DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\
      DROP DATABASE IF EXISTS test;\
      DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';\
      FLUSH PRIVILEGES;" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Installing MariaDB" \
      --msgbox "Deleting anonymous users..." 10 70
    echo "$(date "+%F - %T) - Deleting anonymous users in MariaDB." >> log.txt
    echo "$(date "+%F - %T) - Removing remote access to databases." >> log.txt
    echo "$(date "+%F - %T) - Deleting test database." >> log.txt
    echo "$(date "+%F - %T) - Applying changes." >> log.txt
  fi
}

# Generate database key, create user and database for wordpress.
configmariadbwp() {
  WP_DB_NAME="dbwordpress"
  WP_DB_USER="userwp"
  WP_DB_PASS="$(pwgen -1 -s 16)"
  echo "$DFECHA - Generating password for WordPress user." >> log.txt

  echo "# ===== MARIADB AND WORDPRESS DETAILS AND PASSWORDS =====" >> log.txt
  echo "# =====" >> log.txt
  echo "# ===== MARIADB ROOT PASSWORD:        $DB_ROOT_PASS" >> log.txt
  echo "# =====" >> log.txt  
  echo "# ===== WORDPRESS DATABASE NAME:      $WP_DB_NAME" >> log.txt
  echo "# ===== WORDPRESS DATABASE USER:      $WP_DB_USER" >> log.txt
  echo "# ===== WORDPRESS DATABASE PASSWORD:  $WP_DB_PASS" >> log.txt
  echo "# =====" >> log.txt
  echo "# ============================================ ===========" >> log.txt

  mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; \
    GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; \
    FLUSH PRIVILEGES" | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Configuring Database and passwords." \
      --msgbox "$__RESULT" 10 70
    echo "$DFECHA - Creating database and user for WordPress." >> log.txt
}

# Download latest version of wordpress.
downloadinstallwp() {
  URL="https://wordpress.org/latest.tar.gz"
  wget "$URL" 2>&1 | \
  stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
  dialog \
    --backtitle "$DTITLE" \
    --title "WordPress" \
    --gauge "Descargando..." 10 100
  echo "$(date "+%F - %T) - Downloading the latest version of WordPress from $URL." >> log.txt
}

# Unzip and move the contents of the directory to /var/www/html.
# Set values to improve wordpress performance.
decompressconfigwp() {
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/; rm index.html /var/www/html | \
  dialog --timeout 3 \
    --backtitle "$DTITLE" \
    --title "WordpPress" \
    --msgbox "Configuring WordPress directory" 10 70
    echo "$(date "+%F - %T) - Decompressing file and moving the content." >> log.txt

  	adduser $USER www-data \
    && chown -R $USER:www-data /var/www \
    && chmod 2775 /var/www \
    && find /var/www -type d -exec sudo chmod 2775 {} \; \
    && find /var/www -type f -exec sudo chmod 0664 {} \; | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "WordPress" \
      --msgbox "Estableciendo permisos..." 10 70
    echo "$(date "+%F - %T) - Setting permissions to the web directory to the user $USER." >> log.txt
    sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf
    echo "$(date "+%F - %T) - Adding an entry to the config index." >> log.txt

  echo "" >> /var/www/html/.htaccess  
  echo "php_value memory_limit 256M" >> /var/www/html/.htaccess
  echo "php_value upload_max_filesize 64M" >> /var/www/html/.htaccess
  echo "php_value post_max_size 64M" >> /var/www/html/.htaccess
  echo "php_value max_execution_time 300" >> /var/www/html/.htaccess
  echo "php_value max_input_time 1000" >> /var/www/html/.htaccess
  echo "" >> /var/www/html/wp-config.php
  echo "define( 'FS_METHOD', 'direct' );" >> /var/www/html/wp-config.php

  URLFILE="/etc/apache2/apache2.conf"

  pattern_1="<Directory \/var\/www\/>"
  pattern_2="[ ]*Options Indexes FollowSymLinks\n"
  pattern_3="[ ]*AllowOverride None\n"
  pattern_4="[ ]*Require all granted\n"
  pattern_5="<\/Directory>"
  cpattern="$pattern_1\n$pattern_2$pattern_3$pattern_4$pattern_5"

  replacement_1="<Directory \/var\/www\/>">\n"
  replacement_2="    Options Indexes FollowSymLinks\n"
  replacement_3="    AllowOverride All\n"
  replacement_4="    Require all granted\n"
  replacement_5="<\/Directory>"
  creplacement="$replacement_1$replacement_2$replacement_3$replacement_4$replacement_5"

  sed -i "/$pattern_1/{
    N;N;N;N
    s/$cpattern/$creplacement/
  }" $URLFILE
  echo "$(date "+%F - %T) - Enabling configuration in apache2.conf." >> log.txt
}

# Set rules on the firewall to give access to ssh, http, https.
configfirewall() {
  dialog --timeout 3 \
    --backtitle "$__BTITLE" \
    --title "Enabling Firewall" \
    --msgbox "$__RESULT" 10 70
    echo "$(date "+%F - %T) - Setting firewall rules for ports 22, 80 and 443." >> log.txt
    ufw default deny incoming
    ufw allow ssh
    ufw allow http
    ufw allow https
    echo y | ufw enable
}

# Clean installation cache and files that are no longer needed.
finishclean() {
  dialog --timeout 3 \
	--backtitle "$DTITLE" \
	--title "LAMPW Script 1.0" \
	--msgbox "End of installation." 10 70
    echo "$(date "+%F - %T) - Deleting installation files that are no longer needed.." >> log.txt
    rm latest.tar.gz
    rm -r wordpress/
    rm -rf /var/www/html/index.html
    echo "$(date "+%F - %T) - Clearing package cache." >> log.txt
    apt-get clean
    apt-get autoclean
}

dialog \
	--backtitle "$DTITLE" \
	--title "LAMPW Script 1.0" \
	--msgbox "LAMP and Wordpress server installer." 10 70

updatepack
installapache
installmariadb
configmariadbwp
downloadinstallwp
decompressconfigwp
configfirewall
finishclean
systemctl reload apache2

dialog --clear
echo -e "\n${Yellow} * Installation details in log.txt. DO NOT DELETE THIS FILE.${Color_Off}"
