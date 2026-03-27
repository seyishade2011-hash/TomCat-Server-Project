#!/bin/bash

# Create tomcat user
sudo useradd -m -d /opt/tomcat -U -s /bin/false tomcat

# Update and install java
sudo apt update
sudo apt install default-jdk wget -y

# Fetch the latest Tomcat version and download
cd /tmp
LATEST_VERSION=$(curl -s https://dlcdn.apache.org/tomcat/tomcat-10/ | grep -oP 'v10\.1\.\d+' | sort -V | tail -1)
wget "https://dlcdn.apache.org/tomcat/tomcat-10/${LATEST_VERSION}/bin/apache-tomcat-${LATEST_VERSION#v}.tar.gz"
tar xzvf "apache-tomcat-${LATEST_VERSION#v}.tar.gz" -C /opt/tomcat --strip-components=1

# Set permissions
sudo chown -R tomcat:tomcat /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

# Clean up
rm -f "/tmp/apache-tomcat-${LATEST_VERSION#v}.tar.gz"

# Enabling users on the tomcat server
sudo cat <<EOT> /opt/tomcat/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="admin" />
<role rolename="admin-gui" />     
<role rolename="admin-script" />  
<role rolename="manager" />       
<role rolename="manager-gui" />   
<role rolename="manager-script" />
<role rolename="manager-jmx" />   
<role rolename="manager-status" />
<user username="deployer" password="deployer" roles="manager-script"/>
<user username="admin" password="admin" roles="admin,manager,admin-gui,admin-script,manager-gui,manager-script,manager-jmx,manager-status"/>
</tomcat-users>
EOT

# Making changes to the context.xml file in the manager directory
sudo cat <<EOT> /opt/tomcat/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!--  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
  allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT

# Making changes to the context.xml file in the host-manager directory
sudo cat <<EOT> /opt/tomcat/webapps/host-manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
  <!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve"
  allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT

# Changing the default tomcat port from 8080 to 8085
sudo sed -i 's/Connector port="8080"/Connector port="8085"/g' /opt/tomcat/conf/server.xml

# Create tomcat service file to start and stop tomcat service
sudo cat <<EOT> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Adding the ubuntu user to the tomcat group and give the permissions to webapps directory
sudo chmod 777 /opt/tomcat/webapps
sudo usermod -aG tomcat ubuntu

# Remove the default tomcat home page
sudo mv /opt/tomcat/webapps/ROOT /opt/tomcat/webapps/rootdefault 

# Starting and enabling tomcat service
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
sudo hostnamectl set-hostname Tomcat