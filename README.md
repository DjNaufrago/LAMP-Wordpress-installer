# LAMP / WORDPRESS - INSTALLERS
Bash scrip LAMP and WordPress unattended installers

The first script performs the unattended installation of the Apache web server, the MariaDB database engine, the modules for interpreting PHP, and configures the firewall.

The second script installs the WordPress content management system.

Please read the installation steps carefully.

## PRE-REQUISITES:
- EC2 (AWS) instance with Ubuntu Server 22.04
- Allow SSH, HTTP and HTTPS traffic from anywhere (0.0.0.0/0).

## INSTRUCTIONS INSTALL LAMP:
1. Inside the user directory, download the following file:
2. `wget https://raw.githubusercontent.com/DjNaufrago/LAMP-Wordpress-installer/main/install-lamp.sh`
3. Run the script as follows (no sudo):
4. `bash ./install-lamp.sh`
5. Done, you now have a LAMP server up and running.

Can access through your domain name or public ip address.
The database root password is in log.txt.

## INSTRUCTIONS INSTALL WORDPRESS:
1. First, let's temporarily make our user the owner of the web folder (the script at the end will take care of undoing this).
2. `sudo chown -R $USER:www-data /var/www/`
3. Move to /var/www/html directory and download:
4. `wget https://raw.githubusercontent.com/DjNaufrago/LAMP-Wordpress-installer/main/install-wordpress.sh`
5. The log.txt file from the previous installation must be in the /home/ubuntu directory and must not have been modified. The script will extract from there the root key of the database.
6. Run the script as follows (no sudo):
7. `bash ./install-wordpress.sh`
8. Done, WordPress is installed and running.

Can access through your domain name or public ip address.
Users, passwords and other data are in log.txt.
**To manage your site:** domain/wp-admin or IP/wp-admin

**DO NOT DELETE THE LOG.TXT FILE BEFORE BACKING UP THE DATA!**

## KERNEL MESSAGES
During installation, the operating system will prompt you that some kernel service modules need to be restarted. Accept everything and choose OK. The installation will continue without issue without the need to reboot the entire instance.

## TASKS TO CONFIGURE THE LAMP SERVER:
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
  - **Note:** With this script, it is not necessary to run the secure installation for the database.
### configfirewall
  - Set rules on the firewall to give access to ssh, http, https.
### finishcleanrestart
  - Clean installation cache and files that are no longer needed.
  - Restart the web server for it to take the changes.

## TASKS TO CONFIGURE WORDPRESS:
### configmariadbwp
  - Create the username, password and database for WordPress.
### downloadinstallconfigwp
  - Download the latest core version of WordPress.
  - Register users in web group.
  - Configure and install WordPress.
  - Create and set security values for directories. Prevents PHP code execution.
  - Set the proper permissions for web files and directories.
### configweb
  - Adds features to the web server to make Wordpress the default page.
  - Backup of original files that will be modified.

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
- https://unix.stackexchange.com/questions/507865/add-lines-in-every-public-html-htaccess-file
