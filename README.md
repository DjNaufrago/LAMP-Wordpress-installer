# LAMP-Wordpress-installers
Bash scrip LAMP and WordPress unattended installers

The first script performs the unattended installation of the Apache web server, the MariaDB database engine, the modules for interpreting PHP, and configures the firewall.

The second script installs the WordPress content management system.

Please read the installation steps carefully.

## Pre-Requisites:
- EC2 (AWS) instance with Ubuntu Server 22.04
- Allow SSH, HTTP and HTTPS traffic from anywhere (0.0.0.0/0).

## Instructions:
1. Inside the user directory, download the following file:
2. `wget https://raw.githubusercontent.com/DjNaufrago/LAMP-Wordpress-installer/main/install-lamp.sh`
3. Run the script as follows:
4. bash ./install-lamp.sh
5. move to /var/www/html directory
6. `wget https://raw.githubusercontent.com/DjNaufrago/LAMP-Wordpress-installer/main/install.sh`
7. `bash ./install.sh`

## Things to do:
### startinstall:
  - Create the file log.txt.
### updateupgrade
  - Update repositories list.
  - Update packages that require it.
### installapache
  - Install Apache2 Web Server.
### installphp
- Install PHP modules.
### installmariadb
  - Install MariaDB Database Manager.
  - Automatically generates the password for the root user of the database manager.
  - Remove anonymous users.
  - Remove remote access.
  - Delete test database.
### configmariadbwp
  - Create the username, password and database for WordPress.
### downloadinstallconfigwp
  - Download the latest core version of WordPress.
  - Register users in web group.
  - Configure and install WordPress.
  - Set the proper permissions for web files and directories.
### configweb
  - Adds features to the web server to make Wordpress the default page.
  - Backup of original files that will be modified.
### configfirewall
  - Set rules on the firewall to give access to ssh, http, https.
### finishcleanrestart
  - Clean installation cache and files that are no longer needed.
  - Restart the web server for it to take the changes.

Once the script is executed, can access WordPress through your domain name or public ip address.

**To manage your site:** domain/wp-admin or IP/wp-admin

The user data, passwords and name of the database, are in the file log.txt (**DO NOT DELETE THIS FILE BEFORE COPYING THE DATA!**).

**NOTE:** The next addition to the script will be to be able to choose the modules to install, including the installation of the SSL certificate.

**Sources:**
- https://peteris.rocks/blog/unattended-installation-of-wordpress-on-ubuntu-server/
- https://gist.github.com/beardedinbinary/79d7ad34f9980f0a4c23
- https://docs.aws.amazon.com/es_es/AWSEC2/latest/UserGuide/install-LAMP.html
- https://docs.aws.amazon.com/es_es/AWSEC2/latest/UserGuide/hosting-wordpress.html
- https://crunchify.com/setup-wordpress-amazon-aws-ec2/
- https://github.com/natancabral/shell-script-to-install-multiple-packages/blob/main/run/lamp.sh
- https://linux.how2shout.com/script-to-install-lamp-wordpress-on-ubuntu-20-04-lts-server-quickly-with-one-command/
- https://suriyal.com/install-wordpress-on-amazon-ec2-ubuntu-22-04-instance-or-virtual-machine/
- https://bertvv.github.io/notes-to-self/2015/11/16/automating-mysql_secure_installation/
- https://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
- https://www.plothost.com/kb/create-wordpress-admin-linux-mysql/
