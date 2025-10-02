FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install PowerShell and the Az module
RUN apt-get update \
 && apt-get install -y wget apt-transport-https software-properties-common \
 && wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
 && dpkg -i packages-microsoft-prod.deb \
 && apt-get update \
 && apt-get install -y powershell \
 && pwsh -Command 'Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers'
