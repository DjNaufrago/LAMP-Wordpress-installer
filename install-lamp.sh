#!bin/bash

#
#       Author:   Reinaldo Moreno
#  Description:   Apache web server installer, PHP modules,
#                 MariaDB database and firewall configuration.
#           SO:   Ubuntu Server 22.04
# Architecture:   EC2 Amazon Web Service Instance
#

startinstall() {
  Color_Off='\033[0m'       # Reset
  Green='\033[0;32m'        # Green
  Cyan='\033[0;36m'         # Cyan
  Yellow='\033[0;33m'       # Yellow

  echo -e "${Yellow} * Starting installation... ${Color_Off}"
  touch /home/ubuntu/log.txt
  echo "Unattended installation of LAMP Server" | tee -a $HOME/log.txt
  echo "Author - Reinaldo Moreno" | tee -a $HOME/log.txt
}

# Update repository and install latest packages.
updateupgrade() {
  echo "$(date "+%F - %T") - Update the list of repositories..." | tee -a $HOME/log.txt
  sudo apt-get -y -qq update
  echo "$(date "+%F - %T") - Installing latest packages..." | tee -a $HOME/log.txt
  sudo apt-get -y -qq upgrade
  echo "$(date "+%F - %T") - Installing pwgen password generator." | tee -a $HOME/log.txt
  sudo apt-get install -qq pwgen curl
}
    
# Install apache web server.
installapache() {
  echo "$(date "+%F - %T") - Installing Apache2." | tee -a $HOME/log.txt
	sudo apt-get -qq install apache2
}

# Install PHP modules.
installphp() {
  sudo apt-get -qq install php libapache2-mod-php php-mysql \
  php-common php-cli php-common php-json php-opcache php-readline \
  php-mbstring php-gd php-dom php-zip php-curl
  echo "$(date "+%F - %T") - Installing PHP modules." | tee -a $HOME/log.txt
}

# Install MariaDB Server.
# Generate key for root user.
# Remove anonymous users, remove remote access and delete test database.
installconfigmariadb() {
  echo "$(date "+%F - %T") - Installing MariaDB." | tee -a $HOME/log.txt
  sudo apt-get install -qq mariadb-server

  echo "$(date "+%F - %T") - Generating root key for MariaDB." | tee -a $HOME/log.txt
  DB_ROOT_PASS="$(pwgen -1 -s 16)"

  echo "$(date "+%F - %T") - Setting root password for MariaDB." | tee -a $HOME/log.txt
  sudo mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
    'mysql_native_password', '$.authentication_string', \
    PASSWORD('$DB_ROOT_PASS')) WHERE User='root';"

  echo "$(date "+%F - %T") - Applying privileges to MariaDB root user." | tee -a $HOME/log.txt    
  sudo mysql -e "FLUSH PRIVILEGES;"  

  echo "$(date "+%F - %T") - Deleting anonymous users in MariaDB." | tee -a $HOME/log.txt
  sudo mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='';"
  echo "$(date "+%F - %T") - Removing remote access to databases." | tee -a $HOME/log.txt
  sudo mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  echo "$(date "+%F - %T") - Deleting test database." | tee -a $HOME/log.txt
  sudo mysql -u root -p$DB_ROOT_PASS -e "DROP DATABASE IF EXISTS test;"
  sudo mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  echo "$(date "+%F - %T") - Applying changes." | tee -a $HOME/log.txt
  sudo mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
}


# Set rules on the firewall to give access to ssh, http, https.
configfirewall() {
  echo "$(date "+%F - %T") - Setting firewall rules for ports 22, 80 and 443." | tee -a $HOME/log.txt
  sudo ufw default deny incoming
  sudo ufw allow ssh
  sudo ufw allow http
  sudo ufw allow https
  sudo echo y | sudo ufw enable
  # For Oracle Cloud, comment out the above values and uncomment the following:
  # sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
  # sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
  # sudo netfilter-persistent save
}

# Clean installation cache and files that are no longer needed.
finishcleanrestart() {
  echo "$(date "+%F - %T") - Assigning permissions to the web directory." | tee -a $HOME/log.txt
  sudo adduser $USER www-data
  sudo chmod g+w /var/www -R
  sudo chown -R www-data:www-data /var/www/
  echo -e "ServerName localhost" | sudo tee -a /etc/apache2/apache2.conf
  echo "$(date "+%F - %T") - Clearing package cache an restart web service." | tee -a $HOME/log.txt
  sudo apt-get clean
  sudo apt-get autoclean
  sudo systemctl restart apache2
}

startinstall
updateupgrade
installapache
installphp
installconfigmariadb
configfirewall
finishcleanrestart

echo -e '\n' >> $HOME/log.txt
echo '# ============ MARIADB ROOT PASSWORD ============' >> $HOME/log.txt
echo '# =====' >> $HOME/log.txt
echo "# ===== MARIADB ROOT PASSWORD: $DB_ROOT_PASS" >> $HOME/log.txt
echo '# =====' >> $HOME/log.txt

echo -e "\n${Yellow} * LAMP SERVER IS READY!!!${Color_Off}"
echo -e "\n${Green} * Installation details in /home/ubuntu/log.txt.${Color_Off}"
echo -e "\n${Yellow} * DO NOT DELETE THIS FILE BEFORE COPYING THE DATA.${Color_Off}"
echo -e "\n${Green} * You can access through your domain name or public ip address.${Color_Off}"
