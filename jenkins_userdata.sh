#!/bin/bash
sudo yum update -y
sudo yum install wget -y
sudo yum install maven -y
sudo yum install git -y
sudo yum install java-21-openjdk-devel git -y
sudo yum install wget -y
sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install jenkins --nogpgcheck -y
sudo yum install jenkins -y
sudo systemctl start jenkins
sudo hostnamectl set-hostname Jenkins