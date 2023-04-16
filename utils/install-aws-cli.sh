#!/bin/bash
#aws-cli installer for ubuntu

# install aws cli url convert to zip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "aws-cli.zip"

# install unziper
sudo apt install unzip

#unzip installed zip file
unzip aws-cli.zip

# install aws-cli from the file
sudo ./aws/install

echo "aws --version"