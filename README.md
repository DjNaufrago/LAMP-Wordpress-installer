# LAMP-Wordpress-installer
Bash scrip LAMP and WordPress unattended installer (BETA Version)

This script performs the unattended installation of the Apache web server, the MariaDB database engine, the modules for interpreting PHP, and the WordPress content management system.

## Pre-Requisites:
- EC2 (AWS) instance with Ubuntu Server 22.04
- Allow SSH, HTTP and HTTPS traffic from anywhere (0.0.0.0/0).

## Download:
`wget https://raw.githubusercontent.com/DjNaufrago/LAMP-Wordpress-installer/main/install.sh`

## Perform:
`sudo bash ./install.sh`

## Things to do:
- Create the file log.txt.
- Update repositories list.
- Update packages that require it.
- Install Apache2 Web Server.
- Install PHP modules.
- Install MariaDB Database Manager.
  - Automatically generates the password for the root user of the database manager.
  - Create the username, password and database for WordPress.
  - Remove anonymous users.
  - Remove remote access.
  - Delete test database.
- Download the latest version of WordPress.
  - Unzip the downloaded file.
  - Move the content to the /var/www/html folder
- Sets the permissions for the current user.
- Adds features to the web server to make Wordpress the default page.
- Register users and permissions for WordPress
- Set rules on the firewall to give access to ssh, http, https.
- Backup of original files that will be modified.
- Clean installation cache and files that are no longer needed.
- Restart the web server for it to take the changes.

Once the script is executed, WordPress can be accessed with the ip of the instance.

The user data, passwords and name of the database, are in the file log.txt (**Do not delete this file!**).

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
