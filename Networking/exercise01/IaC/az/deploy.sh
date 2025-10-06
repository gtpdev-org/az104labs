#!/bin/bash
# Deploy networking resources using Azure CLI
# Source configuration
source "$(dirname "$0")/config.sh"

set -e

# Login to Azure
az login

# Create resource group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "Creating Hub VNet and Firewall Subnet..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$HUB_VNET_NAME" \
  --address-prefix "$HUB_VNET_PREFIX" \
  --location "$LOCATION"

az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$HUB_VNET_NAME" \
  --name "$FIREWALL_SUBNET_NAME" \
  --address-prefix "$FIREWALL_SUBNET_PREFIX"

echo "Creating App VNet and subnets..."
az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_VNET_NAME" \
  --address-prefix "$APP_VNET_PREFIX" \
  --location "$LOCATION"

az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$APP_VNET_NAME" \
  --name "$FRONTEND_SUBNET_NAME" \
  --address-prefix "$FRONTEND_SUBNET_PREFIX"

az network vnet subnet create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$APP_VNET_NAME" \
  --name "$BACKEND_SUBNET_NAME" \
  --address-prefix "$BACKEND_SUBNET_PREFIX"

echo "Creating VNet peerings..."
az network vnet peering create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PEERING_HUB_TO_APP" \
  --vnet-name "$HUB_VNET_NAME" \
  --remote-vnet "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$APP_VNET_NAME" \
  --allow-vnet-access

az network vnet peering create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$PEERING_APP_TO_HUB" \
  --vnet-name "$APP_VNET_NAME" \
  --remote-vnet "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$HUB_VNET_NAME" \
  --allow-vnet-access

echo "Deployment complete."
