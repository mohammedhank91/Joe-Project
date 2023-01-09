#!/bin/bash


echo "Value of Param1 is $1";
echo "Value of Param2 is $2";
echo "Value of Param3 is $3";
RANCHER_PROJECT_ID=$3;
#
# Installing Docker first 
#
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo apt-get update
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get update
sudo apt install docker-ce -y

service docker start
docker run hello-world
if [[ "$1" == "0" ]]; then
#
# Start rancher server
#
    docker run -d --restart=unless-stopped -p 8080:8080 --name rancherserver rancher/server
    docker logs rancherserver
#
# Once server is up, run API via container to create project and generate token
#
    docker run -e "RANCHER_SERVER_IP=$2" -e "STEP=all" -e "RANCHER_PROJECT_ID=${RANCHER_PROJECT_ID}" harshals/rsapi

else
#
# Run rsapi container in agent mode to generate token and run it
#
    cmd=$(docker run -e "RANCHER_SERVER_IP=$2" -e "STEP=6" -e "RANCHER_PROJECT_ID=${RANCHER_PROJECT_ID}" harshals/rsapi | tail -n 1);
	if [[ "$(echo $cmd | cut -c 1-11)" == "sudo docker" ]]; then
	    eval $cmd;
	else
	    echo "ERROR : Unable to get token from rancher server";
	fi
fi