#!/bin/bash
# PART 1/2: INSTALACION COMPLETA DE UN SERVIDOR SONARQUBE
#       Requerimientos: - Java 11, Postgresql 14, SonarQube 9.4
#                       - Antes de instalar Sonarqube se debe haber creado la BD en Postgresql

sudo ufw disable
sudo apt update -y && sudo apt upgrade -y

# ---------------- INSTALACION JAVA 11 ----------------------------
sudo apt install openjdk-11-jdk -y

# ---------------- INSTALACION POSTGRESQL 14 ----------------------------
sudo apt -y install gnupg2 wget ca-certificates lsb-release software-properties-common

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
# wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

sudo apt update -y
sudo apt install -y postgresql-13

sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql

usuario_psql=postgres
contrasena_psql=123;
echo "$usuario_psql:$contrasena_psql" | sudo chpasswd
echo "postgres ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# ------------- Crear BD para sonarqube --------------
sudo -u postgres -H -- psql -c "CREATE USER sonar WITH ENCRYPTED PASSWORD '123';"
sudo -u postgres -H -- psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres -H -- psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

sudo systemctl restart postgresql

