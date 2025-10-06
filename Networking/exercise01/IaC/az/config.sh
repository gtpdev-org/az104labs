#!/bin/bash
# Configuration variables for Azure CLI deployment

RESOURCE_GROUP="RG1"
LOCATION="eastus"

# Hub VNet
HUB_VNET_NAME="hub-vnet"
HUB_VNET_PREFIX="10.0.0.0/16"
FIREWALL_SUBNET_NAME="AzureFirewallSubnet"
FIREWALL_SUBNET_PREFIX="10.0.0.0/26"

# App VNet
APP_VNET_NAME="app-vnet"
APP_VNET_PREFIX="10.1.0.0/16"
FRONTEND_SUBNET_NAME="frontend"
FRONTEND_SUBNET_PREFIX="10.1.0.0/24"
BACKEND_SUBNET_NAME="backend"
BACKEND_SUBNET_PREFIX="10.1.1.0/24"

# Peering names
PEERING_HUB_TO_APP="hub-to-app-vnet"
PEERING_APP_TO_HUB="app-vnet-to-hub"
