#!/bin/bash -ex

#1
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

#2 
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

#3
sudo apt-get update -y

sudo apt-get install fontconfig openjdk-11-jre -y

sudo apt-get install jenkins -y

#4
#The apt packages were signed using this key:
# pub   rsa4096 2023-03-27 [SC] [expires: 2026-03-26]
#       63667EE74BBA1F0A08A698725BA31D57EF5975CA
# uid                      Jenkins Project 
# sub   rsa4096 2023-03-27 [E] [expires: 2026-03-26]

#5
# sudo system start jenkins
# don't forget to open 8080 port


#You will need to explicitly install a supported Java runtime environment (JRE), 
# either from your distribution (as described above) or another Java vendor (e.g., Adoptium).
