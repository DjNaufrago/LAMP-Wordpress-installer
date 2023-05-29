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

DFECHA=$(date +"%m-%d-%Y - %H:%M")
echo -e "${Yellow} * Instalando paquetes necesarios... ${Color_Off}"
touch log.txt
echo "$DFECHA - Creando archivo log." >> log.txt
add-apt-repository -yu universe
echo "$DFECHA - Agregando repositorio UNIVERSE y actualizando lista de paquetes." >> log.txt
apt-get install -yq dialog pwgen
echo "$DFECHA - Instalando dialog y pwgen." >> log.txt

DTITLE="Instalacion LAMP Server para WordPress"
DRESULT="Accion Completada"

updatepack() {
  apt-get upgrade -y 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Actualizando Paquetes" \
  	--progressbox 16 60
    echo "$DFECHA - Instalando paquetes mas recientes." >> log.txt
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
    echo "$DFECHA - Instalando Apache2." >> log.txt
  if [ "$?" = 0 ]
  then
    dialog --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando Apache" \
      --msgbox "$DRESULT" 10 70 
  fi
}

installmariadb() {
  DB_ROOT_PASS="$(pwgen -1 -s 16)"
  echo "$DFECHA - Generando clave root para MariaDB = $DB_ROOT_PASS" >> log.txt
  apt-get install -qq mariadb-server 2>&1 | dialog \
    --backtitle "$DTITLE" \
    --title "Instalando MariaDB" \
  	--progressbox 16 60
    echo "$DFECHA - Instalando MariaBD." >> log.txt
  if [ "$?" = 0 ]
  then
    mysql -e "UPDATE mysql.global_priv SET priv=json_set(priv, '$.plugin', \
      'mysql_native_password', '$.authentication_string', \
      PASSWORD('$DB_ROOT_PASS')) WHERE User='root';" | dialog \
      --timeout 3 \
      --backtitle "$DTITLE" \
      --title "Instalando MariaDB" \
      --msgbox "Configurando base de datos y usuario..." 10 70 
      echo "$DFECHA - Estableciendo permisos de administración." >> log.txt
    
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
    echo "$DFECHA - Eliminando usuarios anonimos en MariaDB." >> log.txt
    echo "$DFECHA - Eliminando acceso remoto a las bases de datos." >> log.txt
    echo "$DFECHA - Eliminando base de datos de prueda." >> log.txt
    echo "$DFECHA - Aplicando cambios." >> log.txt
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

downloadwordpress() {
  URL="https://wordpress.org/latest.tar.gz"
  wget "$URL" 2>&1 | \
  stdbuf -o0 awk '/[.] +[0-9][0-9]?[0-9]?%/ { print substr($0,63,3) }' | \
  dialog \
    --backtitle "$DTITLE" \
    --title "WordPress" \
    --gauge "Descargando..." 10 100
  echo "$DFECHA - Descargando la última version de WordPress desde $URL." >> log.txt
}

configdecompresswp() {
	tar -zxf latest.tar.gz; mv wordpress/* /var/www/html/; rm index.html /var/www/html | \
  dialog --timeout 3 \
    --backtitle "$DTITLE" \
    --title "WordpPress" \
    --msgbox "Configurando directorio WordPress" 10 70
    echo "$DFECHA - Descomprimiendo archivo y moviendo el contenido." >> log.txt

  	adduser $USER www-data \
    && chown -R $USER:www-data /var/www \
    && chmod 2775 /var/www \
    && find /var/www -type d -exec sudo chmod 2775 {} \; \
    && find /var/www -type f -exec sudo chmod 0664 {} \; | dialog --timeout 3 \
      --backtitle "$__BTITLE" \
      --title "WordPress" \
      --msgbox "Estableciendo permisos..." 10 70
    echo "$DFECHA - Estableciendo permisos al directorio web al usuario $USER." >> log.txt
    sed -i 's/DirectoryIndex/DirectoryIndex index.php/' /etc/apache2/mods-enabled/dir.conf
    echo "$DFECHA - Agregando entrada al config index." >> log.txt
}

configfirewall() {
  dialog --timeout 3 \
    --backtitle "$__BTITLE" \
    --title "Firewall." \
    --msgbox "$__RESULT" 10 70
    echo "$DFECHA - Estableciendo reglas en el firewall para puertos 22, 80 y 443." >> log.txt
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
    echo "$DFECHA - Eliminando archivos de instalación que ya no son necesarios." >> log.txt
    rm latest.tar.gz
    rm -r wordpress/
    rm -rf /var/www/html/index.html
    echo "$DFECHA - Limpiando cache de paquetes." >> log.txt
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
downloadwordpress
configdecompresswp
configfirewall
finishclean
systemctl reload apache2

dialog --clear
echo -e "\n${Yellow} * Detalles de la instalación en el archivo log.txt. ${Color_Off}"