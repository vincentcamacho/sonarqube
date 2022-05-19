#!/bin/bash
# PART 2/2: INSTALACION COMPLETA DE UN SERVIDOR SONARQUBE
#       Requerimientos: - Java 11, Postgresql 14, SonarQube 9.4
#                       - Antes de instalar Sonarqube se debe haber creado la BD en Postgresql

# ---------------- INSTALACION SONARQUBE 9.4 ----------------------------
cd /tmp
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.4.0.54424.zip
sudo unzip sonarqube-9.4.0.54424.zip -d /opt
# sudo ln -s /opt/sonarqube-9.4.0.54424/ /opt/sonarqube
sudo mv /opt/sonarqube-9.4.0.54424 /opt/sonarqube


# Crear usuario para administrar SonarQube
usuario_sonar=sonar; grupo_sonar=sonar; contrasena_sonar=123; bd_sonar=sonarqube; puerto_sonar=9000
sudo groupadd $grupo_sonar
sudo useradd -c "Usuario para SonarQube" -d /opt/sonarqube -g $grupo_sonar $usuario_sonar
sudo chown -R $usuario_sonar:$grupo_sonar /opt/sonarqube
echo "$usuario_sonar:123" | sudo chpasswd
echo "$usuario_sonar ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Limitar la cantidad de recursos disponibles en el sistema para el usuario que creamos para SonarQube
max_num_archivos_abiertos=131072
max_num_procesos_corriendo=8192

sudo cat <<EOF | sudo tee -a /etc/security/limits.conf
$usuario_sonar   -   nofile   $max_num_archivos_abiertos
$usuario_sonar   -   nproc    $max_num_procesos_corriendo
EOF

# Configurar el archivo mas importante de SonarQube 'sonar.properties'
sudo sed -i "s/#sonar.jdbc.username=/sonar.jdbc.username=$usuario_sonar/g" /opt/sonarqube/conf/sonar.properties
sudo sed -i "s/#sonar.jdbc.password=/sonar.jdbc.password=$contrasena_sonar/g" /opt/sonarqube/conf/sonar.properties
sudo sed -i "s/#sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/sonarqube?currentSchema=my_schema/sonar.jdbc.url=jdbc:postgresql:\/\/localhost\/$bd_sonar/g" /opt/sonarqube/conf/sonar.properties
sudo sed -i "s/#sonar.web.port=9000/sonar.web.port=$puerto_sonar/g" /opt/sonarqube/conf/sonar.properties
sudo sed -i "s/#sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError/sonar.search.javaOpts=-Xmx512m -Xms512m -XX:MaxDirectMemorySize=256m -XX:+HeapDumpOnOutOfMemoryError/g" /opt/sonarqube/conf/sonar.properties
sudo mkdir -p /var/sonarqube/data; sudo mkdir -p /var/sonarqube/temp
sudo chown -R $usuario_sonar:$grupo_sonar /var/sonarqube/data; sudo chown -R $usuario_sonar:$grupo_sonar /var/sonarqube/temp
sudo sed -i 's/#sonar.path.data=data/sonar.path.data=\/var\/sonarqube\/data/g' /opt/sonarqube/conf/sonar.properties
sudo sed -i 's/#sonar.path.temp=temp/sonar.path.temp=\/var\/sonarqube\/temp/g' /opt/sonarqube/conf/sonar.properties

# Editar usuario por defecto en el script 'sonar.sh'
sudo sed -i "s/#RUN_AS_USER=/RUN_AS_USER=$usuario_sonar/g" /opt/sonarqube/bin/linux-x86-64/sonar.sh

# Configurar variables de ambiente (environmental variables)
echo "export SONARQUBE_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
echo "export SONAR_HOME=/opt/sonarqube" | sudo tee -a /etc/profile
echo "export HSO=/opt/sonarqube" | sudo tee -a /etc/profile
source /etc/profile

#Configurar limites en sysctl.conf
sudo cat <<EOF | sudo tee -a /etc/sysctl.conf
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=$max_num_archivos_abiertos
ulimit -n $max_num_archivos_abiertos
ulimit -u $max_num_procesos_corriendo
EOF

#Configurar manualmente el servicio de SonarQube
sudo cat <<EOF | sudo tee /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
User=sonar
Group=sonar
PermissionsStartOnly=true
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
StandardOutput=syslog
LimitNOFILE=$max_num_archivos_abiertos
LimitNPROC=$max_num_procesos_corriendo
TimeoutStartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF

#OJO HAY QUE crear la BD primero y luego iniciar el servicio
# sudo su postgres
# createuser sonar
# psql
# ALTER USER sonar WITH ENCRYPTED password '123';
# CREATE DATABASE sonarqube OWNER sonar;
# grant all privileges on DATABASE sonarqube to sonar;
# \q
# exit
# sudo systemctl restart postgresql
# sudo /opt/sonarqube/bin/linux-x86-64/sonar.sh start

#POSIBLES PROBLEMAS TIPICOS
#No haber creado la BD
#No haber configurado bien 
#No haber configurado bien lo de abajo, ejemplo cuando se reinicia la maquina se pierde esa config
#sudo sysctl -w vm.max_map_count=524288
#sudo sysctl -w fs.file-max=131072
#ulimit -n 131072
#ulimit -u 8192
#Hacer troubleshooting viendo los logs en /opt/sonarqube/logs/sonar.FECHAHOY.log

#ESTO DE ABAJO NO ME FUNCIONO - NO CORRER
# sudo systemctl start sonar
# sudo systemctl enable sonar

#------------------------------------------------------------------------------
# sudo sysctl -w vm.max_map_count=524288
# sudo sysctl -w fs.file-max=131072
# ulimit -n 131072
# ulimit -u 8192

# echo "sysctl -w vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
# echo "sysctl -w fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
# echo "ulimit -n 131072" | sudo tee -a /etc/sysctl.conf
# echo "ulimit -u 8192" | sudo tee -a /etc/sysctl.conf

# echo "sonar   -   nofile   131072" | sudo tee -a /etc/security/limits.conf
# echo "sonar   -   nproc    8192" | sudo tee -a /etc/security/limits.conf
