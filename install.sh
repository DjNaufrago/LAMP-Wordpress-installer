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

echo -e "${Yellow} * Instalando paquetes necesarios... ${Color_Off}"
touch log.txt
echo "$(date "+%F - %T) - Creando archivo log." >> log.txt
add-apt-repository -yu universe
echo "$(date "+%F - %T) - Agregando repositorio UNIVERSE y actualizando lista de paquetes." >> log.txt
apt-get install -yq dialog pwgen
echo "$(date "+%F - %T) - Instalando dialog y pwgen." >> log.txt

DTITLE="Instalacion LAMP Server para WordPress"
DRESULT="Accion Completada"

updatepack() {
  apt-get upgrade -y 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Actualizando Paquetes" \
  	--progressbox 16 60
    echo "$(date "+%F - %T) - Instalando paquetes mas recientes." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Actualizando Paquetes" \
      --msgbox "$DRESULT" 10 70 
  fi
}

installapache() {
	apt-get install -qq apache2 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Instalando Apache" \
  	--progressbox 16 70
    echo "$(date "+%F - %T) - Instalando Apache2." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando Apache" \
      --msgbox "$DRESULT" 10 70 
  fi
}

installphp() {
  apt-get install -qq sudo apt install php libapache2-mod-php php-mysql \
  php-common php-cli php-common php-json php-opcache php-readline \
  php-mbstring php-gd php-dom php-zip php-curl 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Instalando PHP" \
  	--progressbox 16 70
    echo "$(date "+%F - %T) - Instalando modulos PHP." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando PHP" \
      --msgbox "$DRESULT" 10 70 
  fi
}

installmariadb() {
  DB_ROOT_PASS="$(pwgen -1 -s 16)"
  echo "$(date "+%F - %T) - Generando clave root para MariaDB = $DB_ROOT_PASS" >> log.txt
  apt-get install -qq mariadb-server 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Instalando MariaDB" \
  	--progressbox 16 60
    echo "$(date "+%F - %T) - Instalando MariaBD." >> log.txt
  if [ "$?" = 0 ]
  then
    mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
      'mysql_native_password', '$.authentication_string', \
      PASSWORD('$DB_ROOT_PASS')) WHERE User='root';" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando MariaDB" \
      --msgbox "Configurando base de datos y usuario..." 10 70 
      echo "$(date "+%F - %T) - Estableciendo permisos de administración." >> log.txt
    
    mysql -e "FLUSH PRIVILEGES;" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando MariaDB" \
      --msgbox "Aplicando privilegos" 10 70    
    
    mysql -u root -p$DB_ROOT_PASS -e "DELETE FROM mysql.user WHERE User='';\
      DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\
      DROP DATABASE IF EXISTS test;\
      DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';\
      FLUSH PRIVILEGES;" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando MariaDB" \
      --msgbox "Eliminando tablas y usuarios inseguros..." 10 70
    echo "$(date "+%F - %T) - Eliminando usuarios anonimos en MariaDB." >> log.txt
    echo "$(date "+%F - %T) - Eliminando acceso remoto a las bases de datos." >> log.txt
    echo "$(date "+%F - %T) - Eliminando base de datos de prueba." >> log.txt
    echo "$(date "+%F - %T) - Aplicando cambios." >> log.txt
  fi
}

configmariadbwp() {
  WP_DB_NAME="dbwordpress"
  WP_DB_USER="userwp"
  WP_DB_PASS="$(pwgen -1 -s 16)"
  echo "$DFECHA - Generando clave para usuario WordPress." >> log.txt

  echo "# ========== DATOS Y CONTRASEÑAS MARIADB Y WORDPRESS ==========" >> log.txt
  echo "# =====" >> log.txt
  echo "# ===== CONTRASEÑA ROOT MARIA DB:            $DB_ROOT_PASS" >> log.txt
  echo "# =====" >> log.txt  
  echo "# ===== NOMBRE BASE DE DATOS WORDPRESS:      $WP_DB_NAME" >> log.txt
  echo "# ===== USUARIO BASE DE DATOS WORDPRESS:     $WP_DB_USER" >> log.txt
  echo "# ===== CONTRASEÑA BASE DE DATOS WORDPRESS:  $WP_DB_PASS" >> log.txt
  echo "# =====" >> log.txt
  echo "# =============================================================" >> log.txt

  mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME; \
    GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASS'; \
    FLUSH PRIVILEGES" | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "Configurando Base de Datos y contraseñas." \
      --msgbox "$__RESULT" 10 70
    echo "$DFECHA - Creando base de datos y usuario para WordPress." >> log.txt
}

downloadinstallwp() {
  URL="https://wordpress.org/latest.tar.gz"
  wget "$URL" 2>&1 | \
  stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
  dialog \
    --backtitle "$DTITLE" \
    --title "WordPress" \
    --gauge "Descargando..." 10 100
  echo "$(date "+%F - %T) - Descargando la última version de WordPress desde $URL." >> log.txt
}

decompressconfigwp() {
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/; rm index.html /var/www/html | \
  dialog --timeout 3 \
    --backtitle "$DTITLE" \
    --title "WordpPress" \
    --msgbox "Configurando directorio WordPress" 10 70
    echo "$(date "+%F - %T) - Descomprimiendo archivo y moviendo el contenido." >> log.txt

  	adduser $USER www-data \
    && chown -R $USER:www-data /var/www \
    && chmod 2775 /var/www \
    && find /var/www -type d -exec sudo chmod 2775 {} \; \
    && find /var/www -type f -exec sudo chmod 0664 {} \; | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "WordPress" \
      --msgbox "Estableciendo permisos..." 10 70
    echo "$(date "+%F - %T) - Estableciendo permisos al directorio web al usuario $USER." >> log.txt
    sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf
    echo "$(date "+%F - %T) - Agregando entrada al config index." >> log.txt

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
  echo "$(date "+%F - %T) - Habilitando configuracion en apache2.conf." >> log.txt
}

configfirewall() {
  dialog --timeout 3 \
    --backtitle "$__BTITLE" \
    --title "Activando Firewall." \
    --msgbox "$__RESULT" 10 70
    echo "$(date "+%F - %T) - Estableciendo reglas en el firewall para puertos 22, 80 y 443." >> log.txt
    ufw default deny incoming
    ufw allow ssh
    ufw allow http
    ufw allow https
    echo y | ufw enable
}

finishclean() {
  dialog --timeout 3 \
	--backtitle "$DTITLE" \
	--title "LAMPW Script 1.0" \
	--msgbox "Fin de la instalación." 10 70
    echo "$(date "+%F - %T) - Eliminando archivos de instalación que ya no son necesarios." >> log.txt
    rm latest.tar.gz
    rm -r wordpress/
    rm -rf /var/www/html/index.html
    echo "$(date "+%F - %T) - Limpiando cache de paquetes." >> log.txt
    apt-get clean
    apt-get autoclean
}

dialog \
	--backtitle "$DTITLE" \
	--title "LAMPW Script 1.0" \
	--msgbox "Instalador de servidor LAMP para Wordpress." 10 70

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
echo -e "\n${Yellow} * Detalles de la instalación en el archivo log.txt. ${Color_Off}"