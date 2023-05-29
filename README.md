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
- Add repository universe.
- Update repositories and install.
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
- Set rules on the firewall to give access to ssh, http, https.
- Clean installation cache and files that are no longer needed.
- Restart the web server for it to take the changes.

Once the script is executed, WordPress can be accessed with the ip of the instance.

The user data, passwords and name of the database, are in the file log.txt (**Do not delete this file!**).
