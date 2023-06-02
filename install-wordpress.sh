#!bin/bash

#
#       Author:   Reinaldo Moreno
#  Description:   Apache web server installer, PHP modules,
#                 MariaDB database, firewall configuration
#                 and Wordpress.
#           SO:   Ubuntu Server 22.04
# Architecture:   EC2 Amazon Web Service Instance
#

DB_ROOT_PASS=""

startinstall() {
  Color_Off='\033[0m'       # Reset
  Green='\033[0;32m'        # Green
  Cyan='\033[0;36m'         # Cyan
  Yellow='\033[0;33m'       # Yellow

  echo -e "${Yellow} * Starting installation... ${Color_Off}"
  echo -e '\n' >> /home/ubuntu/log.txt  
  echo '# ========================== WORDPRESS =============================' >> /home/ubuntu/log.txt
  echo -e '\n' >> /home/ubuntu/log.txt 
  echo "Unattended installation of WordPress" | tee -a /home/ubuntu/log.txt
  echo "Author - Reinaldo Moreno" | tee -a /home/ubuntu/log.txt
}

# Generate database key, create user and database for wordpress.
configmariadbwp() {
  echo "$(date "+%F - %T") - Generating password for WordPress user." | tee -a /home/ubuntu/log.txt
  WP_DB_NAME="dbwordpress"
  WP_DB_USER="userwp"
  WP_DB_PASS="$(pwgen -1 -s 16)"
  WP_ADMIN_USER="wpadmin"
  WP_ADMIN_PASS="$(pwgen -1 -s 8)"
  WP_PREFIX="wp_"
  MY_IP="$(curl https://checkip.amazonaws.com)"

  echo -e '\n' >> /home/ubuntu/log.txt
  echo '# ===== MARIADB AND WORDPRESS DETAILS AND PASSWORDS =====' >> /home/ubuntu/log.txt
  echo '# =====' >> /home/ubuntu/log.txt
  echo "# ===== MARIADB ROOT PASSWORD:        $DB_ROOT_PASS" >> /home/ubuntu/log.txt
  echo '# =====' >> /home/ubuntu/log.txt  
  echo "# ===== WORDPRESS DATABASE NAME:      $WP_DB_NAME" >> /home/ubuntu/log.txt
  echo "# ===== WORDPRESS DATABASE USER:      $WP_DB_USER" >> /home/ubuntu/log.txt
  echo "# ===== WORDPRESS DATABASE PASSWORD:  $WP_DB_PASS" >> /home/ubuntu/log.txt
  echo '# =====' >> /home/ubuntu/log.txt
  echo "# ===== WORDPRESS ADMIN USER:         $WP_ADMIN_USER" >> /home/ubuntu/log.txt
  echo "# ===== WORDPRESS ADMIN PASSWORD:     $WP_ADMIN_PASS" >> /home/ubuntu/log.txt
  echo "# ===== WORDPRESS TABLE PREFIX:       $WP_PREFIX" >> /home/ubuntu/log.txt
  echo '# =====' >> /home/ubuntu/log.txt
  echo "# ===== MY EXTERNAL IP:               $MY_IP" >> /home/ubuntu/log.txt
  echo '# =====' >> /home/ubuntu/log.txt
  echo '# =======================================================' >> /home/ubuntu/log.txt
  echo -e '\n' >> /home/ubuntu/log.txt

  echo "$(date "+%F - %T") - Creating database and user for WordPress." | tee -a /home/ubuntu/log.txt
  sudo mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; \
    GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; \
    FLUSH PRIVILEGES"
}

# Download latest version of wordpress.
# Unzip and move the contents of the directory to /var/www/html.
downloadinstallconfigwp() {
  sudo adduser $USER www-data
  sudo chmod g+w /var/www -R
  sudo chown -R www-data:www-data /var/www/

  echo "$(date "+%F - %T") - Downloading the command-line interface for WordPress (WP-CLI)." | tee -a /home/ubuntu/log.txt
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  sudo mv wp-cli.phar /usr/local/bin/wp

  echo "$(date "+%F - %T") - Downloading the latest version of WordPress." | tee -a /home/ubuntu/log.txt
  wp core download
  wp core config --dbhost=localhost --dbprefix=$WP_PREFIX --dbname=$WP_DB_NAME --dbuser=$WP_DB_USER --dbpass=$WP_DB_PASS
  wp core install --url=$MY_IP --title="My New Site" --admin_name=wpadmin --admin_password=$WP_ADMIN_PASS --admin_email=you@example.com
  wp config set --add FS_METHOD direct
  sudo rm /var/www/html/index.html
  sudo find /var/www -type d -exec sudo chmod 2775 {} \;
  sudo find /var/www -type f -exec sudo chmod 0664 {} \;
}

# Enabling settings for WordPress
configweb() {
  sudo cp /etc/apache2/mods-enabled/dir.conf /etc/apache2/mods-enabled/dir.conf.bk
  echo "$(date "+%F - %T") - Adding an entry to the config index." | tee -a /home/ubuntu/log.txt
  sudo sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf

  echo "$(date "+%F - %T") - Enabling configuration in apache2.conf." | tee -a /home/ubuntu/log.txt
  sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bk
  URLFILE="/etc/apache2/apache2.conf"
	NEWTEXT="         AllowOverride All"
	LINENUMBER="$( (awk '/<Directory \/var\/www\/>/,/<\/Directory>/ {printf NR "  "; print}' \
    $URLFILE | grep AllowOverride) | grep -Eo '[0-9]{1,3}' )"
  sudo sed -i "${LINENUMBER}s/.*/$NEWTEXT/" $URLFILE

  echo "$(date "+%F - %T") - Update web values for best performance." | tee -a /home/ubuntu/log.txt
  sudo cp /etc/php/8.1/apache2/php.ini /etc/php/8.1/apache2/php.ini.bk
  sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/8.1/apache2/php.ini
  sudo sed -i 's/post_max_size = 8M/post_max_size = 128M/' /etc/php/8.1/apache2/php.ini
  sudo sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/8.1/apache2/php.ini
  sudo sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/8.1/apache2/php.ini
  sudo sed -i 's/max_input_time = 60/max_input_time = 300/' /etc/php/8.1/apache2/php.ini

  echo '=== Copies of the original configuration files were created:' | tee -a /home/ubuntu/log.txt
  echo '=== - /etc/apache2/mods-enabled/dir.conf.bk' | tee -a /home/ubuntu/log.txt
  echo '=== - /etc/apache2/apache2.conf.bk' | tee -a /home/ubuntu/log.txt
  echo '=== - /etc/php/8.1/apache2/php.ini.bk' | tee -a /home/ubuntu/log.txt
  
  sudo systemctl restart apache2
}

RUNFOLDER="/var/www/html"

if [ -z "$DB_ROOT_PASS"]; then
    echo -e "\n${Cyan} * ERROR * MARIADB ROOT KEY IS EMPTY.${Color_Off}"
    echo -e "\n${Yellow} * YOU MUST COPY THE MARIADB ROOT KEY TO THE BEGINNING OF THE FILE.${Color_Off}"
    echo -e "\n${Yellow} * BETWEEN THE QUOTES AFTER DB_ROOT_PASS.${Color_Off}"   
else
    if [ $PWD != $RUNFOLDER]; then
        startinstall
        configmariadbwp
        downloadinstallconfigwp
        configweb
        echo -e '\n' >> /home/ubuntu/log.txt
        echo 'Remember to change the WordPress admin email in Settings / General.' >> /home/ubuntu/log.txt
        echo -e "\n${Yellow} * WORDPRESS IS READY!!!${Color_Off}"
        echo -e "\n${Green} * Installation details in /home/ubuntu/log.txt.${Color_Off}"
        echo -e "\n${Yellow} * DO NOT DELETE THIS FILE BEFORE COPYING THE DATA.${Color_Off}"
        echo -e "\n${Green} * You can access through your domain name or public ip address.${Color_Off}"
        echo -e "\n${Green} * To manage your site: domain/wp-admin or IP/wp-admin.${Color_Off}"
    else
        echo -e "\n${Cyan} * ERROR * YOU MUST RUN THE SCRIPT INSIDE THE FOLDER: $RUNFOLDER.${Color_Off}"
    fi
fi