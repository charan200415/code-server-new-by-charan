#FROM debian:10
FROM ubuntu:20.04

LABEL AboutImage "VS-Code-Server V2"

LABEL Maintainer "Charan"

ARG DEBIAN_FRONTEND=noninteractive
#Code-Server Version
ENV	CS_VERSION=3.11.0 \
#Code-Server login type: {password, none}
	AUTH_TYPE="password" \
#Code-Server login password (If AUTH_TYPE=password)
	PASSWORD="samplepass" \
#Code-Server access port
	CODESERVER_PORT=$PORT \
#Custom Home Directory for Heroku
	CUSTOM_HOME="/app" \
#Home Directory
	HOME=$CUSTOM_HOME \
#Workspace Directory
	WORKSPACE_DIR=$CUSTOM_HOME"/WORKSPACE" \
#Ngrok Port Forwarder Token
	NGROK_TOKEN="1tLI5XxmWy9UHmolHDVvxmgOwvU_4qG9dbxDayGJSyuEiq3A1" \
#System Path Variable
	PATH=/usr/local/go/bin:/usr/local/cargo/bin:$PATH \
	RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
#Timezone
	TZ="Asia/Kolkata" \
#Locales
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=C.UTF-8
RUN apt-get update  \
	&& apt-get install -y \
# Base Packages
	tzdata software-properties-common apt-transport-https wget git curl vim nano zip sudo net-tools xvfb php npm supervisor gnupg \
# C, C++
	build-essential \
# Python
	python3 \
	python3-pip \
# Ruby
	ruby  \
# Nodejs(LTS Release)
	&& bash -c 'echo "Installing Nodejs..."'  \
	&& wget https://nodejs.org/dist/v14.17.0/node-v14.17.0-linux-x64.tar.xz -P /tmp  \
	&& tar -xvf /tmp/node-v14.17.0-linux-x64.tar.xz -C /tmp > /dev/null 2>&1  \
	&& cp -r /tmp/node-v14.17.0-linux-x64/* /usr \
	&& bash -c 'echo "Installed Nodejs!"' \
# PowerShell
	&& wget -q https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -P /tmp  \
	&& apt install -y  /tmp/packages-microsoft-prod.deb  \
	&& apt-get update  \
	&& apt-get install -y powershell  \
# Brave
	&& curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg  \
	&& echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|tee /etc/apt/sources.list.d/brave-browser-release.list  \
	&& apt update  \
	&& apt install brave-browser -y  \
# Code-Server
	&& bash -c 'echo -e "Installing Code-Server..."' \
	&& ARCH=$(dpkg --print-architecture) \
	&& wget  -O /tmp/code-server.deb "https://github.com/coder/code-server/releases/download/v4.2.0/code-server_4.2.0_amd64.deb" \
	&& apt install -y /tmp/code-server.deb \
	&& bash -c 'echo -e "Code-Server Installed!"'  \
# Code-Server Extensions
	&& mkdir $CUSTOM_HOME/ \
	&& mkdir $CUSTOM_HOME/.extensions \
	&& chmod 777 -R $CUSTOM_HOME/.extensions \
	&& for codextension in \
	pkief.material-icon-theme \
	akamud.vscode-theme-onedark \
	ms-python.python \
	; do code-server --install-extension $codextension --extensions-dir $CUSTOM_HOME/.extensions; done  \
# Jupyter Prerequisites
	&& pip3 install -U pylint ipykernel  \
# timezone
	&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \  
# Cleanup
	&& apt-get clean  \
	&& rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/* 
#Requests install 
RUN pip3 install requests pytz
#Install req
# Install unzip + rclone (support for remote filesystem)
RUN apt-get update && apt-get install unzip -y
RUN curl https://rclone.org/install.sh | bash
RUN apt-get install build-essential cmake -y

RUN apt-get install libgtk-3-dev -y

RUN apt-get install libboost-all-dev -y
RUN  pip install face-recognition

COPY container/home/ $CUSTOM_HOME/

COPY container/code-server/User/ /usr/local/share/code-server/User/
COPY container/code-server/pages/ /usr/lib/code-server/src/browser/pages/
COPY container/code-server/media/ /usr/lib/code-server/src/browser/media/

RUN chmod -R ug+rwx $CUSTOM_HOME/  \
	&& chmod -R ug+rwx /usr/local/share/code-server/User

CMD supervisord -c $CUSTOM_HOME/.supervisord.conf
