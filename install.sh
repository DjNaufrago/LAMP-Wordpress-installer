#!bin/bash

#
#       Author:   Reinaldo Moreno
#  Description:   Apache web server installer, PHP modules,
#                 MariaDB database, firewall configuration
#                 and Wordpress.
#           SO:   Ubuntu Server 22.04
# Architecture:   EC2 Amazon Web Service Instance
#

# Color
Color_Off='\033[0m'       # Reset
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan

echo -e "${Blue} * Instando paquetes necesarios... ${Color_Off}"
apt-get install -qy dialog pwgen

__BTITLE="Instalacion LAMP Server para WordPress"
__RESULT="Accion Completada"

echo -e "${Yellow} * Creando archhivo log... ${Color_Off}"
touch log.txt

updaterepo() {
  apt-get update 2>&1 | tee -a log.txt | dialog \
    --backtitle "$__BTITLE" \
    --title "Actualizacion Repositorios" \
  	--progressbox 16 70
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Actualizacion Repositorios" \
      --msgbox "$__RESULT" 10 70 
  fi
}

updatepack() {
  apt-get upgrade -y 2>&1 | tee -a log.txt | dialog \
    --backtitle "$__BTITLE" \
    --title "Actualizando Paquetes" \
  	--progressbox 16 60
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Actualizando Paquetes" \
      --msgbox "$__RESULT" 10 70 
  fi
}

installapache() {
	apt-get install -y apache2 2>&1 | tee -a log.txt | dialog \
    --backtitle "$__BTITLE" \
    --title "Instalando Apache" \
  	--progressbox 16 70
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Instalando Apache" \
      --msgbox "$__RESULT" 10 70 
  fi
}

installmariadb() {
  __MARIADB_ROOT_PASSWORD="$(pwgen -1 -s 16)"
  debconf-set-selections <<< "mariadb-server mysql-server/root_password password $__MARIADB_ROOT_PASSWORD"
  debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $__MARIADB_ROOT_PASSWORD" 
  apt-get install -y mariadb-server 2>&1 | tee -a log.txt | dialog \
    --backtitle "$__BTITLE" \
    --title "Instalando MariaDB" \
  	--progressbox 16 60
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Instalando MariaDB" \
      --msgbox "$__RESULT" 10 70 
  fi  
}

configmariadbwp(){
  __WP_DB_NAME="wordpress-db"
  __WP_DB_USERNAME="wordpress-user"
  __WP_DB_PASSWORD="$(pwgen -1 -s 16)"

  echo "########## DATOS Y CONTRASEÑAS MARIADB Y WORDPRESS #######################" >> log.txt
  echo "##########" >> log.txt
  echo "########## CONTRASEÑA ROOT MARIA DB:            $__MARIADB_ROOT_PASSWORD" >> log.txt
  echo "##########" >> log.txt  
  echo "########## NOMBRE BASE DE DATOS WORDPRESS:      $__WP_DB_NAME" >> log.txt
  echo "########## USUARIO BASE DE DATOS WORDPRESS:     $__WP_DB_USERNAME" >> log.txt
  echo "########## CONTRASEÑA BASE DE DATOS WORDPRESS:  $__WP_DB_PASSWORD" >> log.txt
  echo "##########" >> log.txt
  echo "###########################################################################" >> log.txt

  mysql -uroot -p$__MARIADB_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $__WP_DB_NAME; \
    GRANT ALL ON $__WP_DB_NAME.* TO '$__WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$__WP_DB_PASSWORD'; \
    FLUSH PRIVILEGES" | tee -a log.txt | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Configurando Base de Datos y contraseñas." \
      --msgbox "$__RESULT" 10 70 
}

downloadwordpress() {
  URL="https://wordpress.org/latest.tar.gz"
  wget "$URL" 2>&1 | \
  stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
  dialog \
    --backtitle "$__BTITLE" \
    --title "WordPress" \
    --gauge "Descargando..." 10 100
}

decompresswp() {
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/; rm index.html /var/www/html | \
  dialog --timeout 3 \
    --backtitle "$__BTITLE" \
    --title "WordpPress" \
    --msgbox "Configurando directorio WordPress" 10 70 
  	adduser $USER www-data \
    && chown -R $USER:www-data /var/www \
    && chmod 2775 /var/www \
    && find /var/www -type d -exec sudo chmod 2775 {} \; \
    && find /var/www -type f -exec sudo chmod 0664 {} \; | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "WordPress" \
      --msgbox "Estableciendo permisos..." 10 70
  rm latest.tar.gz
  rm -r wordpress/
  rm -rf /var/www/html/index.html
  sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf
}

configfirewall() {
  ufw default deny incoming
  ufw allow ssh
  ufw allow http
  ufw allow https
  echo y | ufw enable
}

executefunctions() {
	updaterepo
        updatepack
        installapache
        installmariadb
        configmariadbwp
        downloadwordpress
        decompresswp
        configfirewall
        systemctl reload apache2
}

dialog \
	--backtitle "$__BTITLE" \
	--title "LAMPW Script 1.0" \
	--msgbox "Instalador de servidor LAMP para Wordpress." 10 70

dialog \
	--backtitle "$__BTITLE" \
	--title "Accion requerida" \
	--yesno "Este script realizara cambios en la configuracion e instalara paquetes ¿Desea continuar?" 10 70
case $response in
    0)
	executefunctions
   ;;
   1)
        exit 1
        echo "Proceso cancelado por el usuario" >> log.txt
   ;;
   255)
        echo "[ESC] key pressed." >> log.txt
   ;;
esac	

dialog --clear
echo -e "\n${Green} * Fin del proceso. ${Color_Off}"
echo -e "\n${Yellow} * Detalles de la instalación en el archivo log.txt. ${Color_Off}"
