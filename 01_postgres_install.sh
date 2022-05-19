#!/bin/bash
# PART 1/2: INSTALACION COMPLETA DE UN SERVIDOR SONARQUBE
#       Requerimientos: - Java 11, Postgresql 14, SonarQube 9.4
#                       - Antes de instalar Sonarqube se debe haber creado la BD en Postgresql

sudo ufw disable
sudo apt update -y && sudo apt upgrade -y

# ---------------- INSTALACION JAVA 11 ----------------------------
sudo apt install openjdk-11-jdk -y

# ---------------- INSTALACION POSTGRESQL 14 ----------------------------
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
# wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo apt update -y
sudo apt install postgresql -y
sudo systemctl start postgresql; sudo systemctl enable postgresql

usuario_psql=postgres; contrasena_psql=123;
echo "$usuario_psql:$contrasena_psql" | sudo chpasswd
echo "postgres ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# ------ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ ↓ 
        #OJO CREAR LA BASE DE DATOS ANTES DE INSTALAR SONARQUBE
        # sudo su postgres
        # createuser sonar
        # psql
                # ALTER USER "sonar" WITH ENCRYPTED password '123';
                # CREATE DATABASE sonarqube OWNER sonar;
                # grant all privileges on DATABASE sonarqube to sonar;
                # \q
                # exit
                # sudo systemctl restart postgresql
