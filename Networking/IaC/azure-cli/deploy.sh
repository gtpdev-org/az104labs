#!/bin/bash
# --------------------------------
# Azure Resource Deployment Script (Azure CLI)
# --------------------------------

set -e

# -------------------------------
# Login to Azure and set subscription
# -------------------------------
echo -e "${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code

# Set subscription (optional: can be set by name or id)
# az account set --subscription "$SUBSCRIPTION_ID"

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# -------------------------------
# Load configuration (JSON format)
# -------------------------------
CONFIG_PATH="$(dirname "$0")/config.json"
echo -e "${CYAN}Loading configuration from $CONFIG_PATH${NC}"

if [ ! -f "$CONFIG_PATH" ]; then
    echo -e "${RED}Configuration file not found: $CONFIG_PATH${NC}"
    exit 1
fi

# Load config values
RESOURCE_GROUP=$(jq -r '.ResourceGroupName' "$CONFIG_PATH")
LOCATION=$(jq -r '.Location' "$CONFIG_PATH")

# Networking
HUB_VNET_NAME=$(jq -r '.Networking.HubVNet.Name' "$CONFIG_PATH")
HUB_VNET_PREFIX=$(jq -r '.Networking.HubVNet.AddressPrefix' "$CONFIG_PATH")
FIREWALL_SUBNET_NAME=$(jq -r '.Networking.HubVNet.FirewallSubnet.Name' "$CONFIG_PATH")
FIREWALL_SUBNET_PREFIX=$(jq -r '.Networking.HubVNet.FirewallSubnet.AddressPrefix' "$CONFIG_PATH")
APP_VNET_NAME=$(jq -r '.Networking.AppVNet.Name' "$CONFIG_PATH")
APP_VNET_PREFIX=$(jq -r '.Networking.AppVNet.AddressPrefix' "$CONFIG_PATH")
FRONTEND_SUBNET_NAME=$(jq -r '.Networking.AppVNet.FrontendSubnet.Name' "$CONFIG_PATH")
FRONTEND_SUBNET_PREFIX=$(jq -r '.Networking.AppVNet.FrontendSubnet.AddressPrefix' "$CONFIG_PATH")
BACKEND_SUBNET_NAME=$(jq -r '.Networking.AppVNet.BackendSubnet.Name' "$CONFIG_PATH")
BACKEND_SUBNET_PREFIX=$(jq -r '.Networking.AppVNet.BackendSubnet.AddressPrefix' "$CONFIG_PATH")
ASG_NAME=$(jq -r '.Networking.ASG.Name' "$CONFIG_PATH")
NSG_NAME=$(jq -r '.Networking.NSG.Name' "$CONFIG_PATH")
PEERING_HUB_TO_APP=$(jq -r '.Networking.Peerings.HubToApp' "$CONFIG_PATH")
PEERING_APP_TO_HUB=$(jq -r '.Networking.Peerings.AppToHub' "$CONFIG_PATH")

# VMs
VM1_NAME=$(jq -r '.VirtualMachines.VM1.Name' "$CONFIG_PATH")
VM2_NAME=$(jq -r '.VirtualMachines.VM2.Name' "$CONFIG_PATH")
VM_SIZE=$(jq -r '.VirtualMachines.Size' "$CONFIG_PATH")
VM_IMAGE_PUBLISHER=$(jq -r '.VirtualMachines.Image.Publisher' "$CONFIG_PATH")
VM_IMAGE_OFFER=$(jq -r '.VirtualMachines.Image.Offer' "$CONFIG_PATH")
VM_IMAGE_SKU=$(jq -r '.VirtualMachines.Image.Sku' "$CONFIG_PATH")
VM_IMAGE_VERSION=$(jq -r '.VirtualMachines.Image.Version' "$CONFIG_PATH")
VM_DISK_SIZE=$(jq -r '.VirtualMachines.Disk.SizeGB' "$CONFIG_PATH")
VM_DISK_TYPE=$(jq -r '.VirtualMachines.Disk.StorageAccountType' "$CONFIG_PATH")
VM_DISK_CACHING=$(jq -r '.VirtualMachines.Disk.Caching' "$CONFIG_PATH")
VM_DISK_CREATE_OPTION=$(jq -r '.VirtualMachines.Disk.CreateOption' "$CONFIG_PATH")
VM1_PUBLICIP_NAME=$(jq -r '.VirtualMachines.VM1.PublicIP.Name' "$CONFIG_PATH")
VM2_PUBLICIP_NAME=$(jq -r '.VirtualMachines.VM2.PublicIP.Name' "$CONFIG_PATH")
VM1_NIC_NAME=$(jq -r '.VirtualMachines.VM1.NIC.Name' "$CONFIG_PATH")
VM2_NIC_NAME=$(jq -r '.VirtualMachines.VM2.NIC.Name' "$CONFIG_PATH")

# -------------------------------
# Prompt for VM admin credentials
# -------------------------------
echo -e "${CYAN}Enter the VM admin username:${NC}"
read VM_ADMIN_USER
read -s -p "Enter the VM admin password: " VM_ADMIN_PASSWORD
echo

# -------------------------------
# Resource Group Creation
# -------------------------------
EXISTING_RG=$(az group show --name "$RESOURCE_GROUP" --query "name" -o tsv 2>/dev/null || true)
if [ "$EXISTING_RG" == "$RESOURCE_GROUP" ]; then
    echo -e "${RED}Resource Group '$RESOURCE_GROUP' already exists. Deleting...${NC}"
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    echo -e "${GREEN}Waiting for Resource Group deletion...${NC}"
    az group wait --name "$RESOURCE_GROUP" --deleted
fi

echo -e "${YELLOW}Creating Resource Group '$RESOURCE_GROUP' in '$LOCATION'...${NC}"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# -------------------------------
# Create Hub VNet and Firewall Subnet
# -------------------------------
echo -e "${YELLOW}Creating Hub VNet...${NC}"
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

echo -e "${GREEN}Hub VNet and Firewall Subnet created.${NC}"

# -------------------------------
# Create App VNet and Subnets
# -------------------------------
echo -e "${YELLOW}Creating App VNet...${NC}"
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

echo -e "${GREEN}App VNet and Subnets created.${NC}"

# -------------------------------
# Create VNet Peerings
# -------------------------------
HUB_VNET_ID=$(az network vnet show --resource-group "$RESOURCE_GROUP" --name "$HUB_VNET_NAME" --query id -o tsv)
APP_VNET_ID=$(az network vnet show --resource-group "$RESOURCE_GROUP" --name "$APP_VNET_NAME" --query id -o tsv)

echo -e "${YELLOW}Creating VNet Peerings...${NC}"
az network vnet peering create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$HUB_VNET_NAME" \
  --name "$PEERING_HUB_TO_APP" \
  --remote-vnet "$APP_VNET_ID" \
  --allow-forwarded-traffic true

az network vnet peering create \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$APP_VNET_NAME" \
  --name "$PEERING_APP_TO_HUB" \
  --remote-vnet "$HUB_VNET_ID" \
  --allow-forwarded-traffic true

echo -e "${GREEN}VNet Peerings created.${NC}"

# -------------------------------
# Create Public IPs
# -------------------------------
echo -e "${YELLOW}Creating Public IPs...${NC}"
az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM1_PUBLICIP_NAME" \
  --allocation-method Static \
  --location "$LOCATION"

az network public-ip create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM2_PUBLICIP_NAME" \
  --allocation-method Static \
  --location "$LOCATION"

echo -e "${GREEN}Public IPs created.${NC}"

# -------------------------------
# Create Application Security Group
# -------------------------------
echo -e "${YELLOW}Creating Application Security Group...${NC}"
az network asg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ASG_NAME" \
  --location "$LOCATION"

# -------------------------------
# Create Network Security Group and Rule
# -------------------------------
echo -e "${YELLOW}Creating Network Security Group and SSH rule...${NC}"
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG_NAME" \
  --location "$LOCATION"

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name AllowSSH \
  --priority 100 \
  --access Allow \
  --direction Inbound \
  --protocol Tcp \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 22

echo -e "${GREEN}NSG and SSH rule created.${NC}"

# -------------------------------
# Create NICs
# -------------------------------
FRONTEND_SUBNET_ID=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$APP_VNET_NAME" --name "$FRONTEND_SUBNET_NAME" --query id -o tsv)
BACKEND_SUBNET_ID=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$APP_VNET_NAME" --name "$BACKEND_SUBNET_NAME" --query id -o tsv)
ASG_ID=$(az network asg show --resource-group "$RESOURCE_GROUP" --name "$ASG_NAME" --query id -o tsv)
NSG_ID=$(az network nsg show --resource-group "$RESOURCE_GROUP" --name "$NSG_NAME" --query id -o tsv)
VM1_PUBLICIP_ID=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$VM1_PUBLICIP_NAME" --query id -o tsv)
VM2_PUBLICIP_ID=$(az network public-ip show --resource-group "$RESOURCE_GROUP" --name "$VM2_PUBLICIP_NAME" --query id -o tsv)

echo -e "${YELLOW}Creating NICs...${NC}"
az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM1_NIC_NAME" \
  --subnet "$FRONTEND_SUBNET_ID" \
  --public-ip-address "$VM1_PUBLICIP_ID" \
  --application-security-group "$ASG_ID"

az network nic create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM2_NIC_NAME" \
  --subnet "$BACKEND_SUBNET_ID" \
  --public-ip-address "$VM2_PUBLICIP_ID" \
  --network-security-group "$NSG_ID"

echo -e "${GREEN}NICs created.${NC}"

# -------------------------------
# Create Virtual Machines
# -------------------------------
echo -e "${YELLOW}Creating Virtual Machines...${NC}"
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM1_NAME" \
  --image "$VM_IMAGE_PUBLISHER:$VM_IMAGE_OFFER:$VM_IMAGE_SKU:$VM_IMAGE_VERSION" \
  --size "$VM_SIZE" \
  --admin-username "$VM_ADMIN_USER" \
  --admin-password "$VM_ADMIN_PASSWORD" \
  --nics "$VM1_NIC_NAME" \
  --os-disk-size-gb "$VM_DISK_SIZE" \
  --storage-sku "$VM_DISK_TYPE" \
  --authentication-type password

az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM2_NAME" \
  --image "$VM_IMAGE_PUBLISHER:$VM_IMAGE_OFFER:$VM_IMAGE_SKU:$VM_IMAGE_VERSION" \
  --size "$VM_SIZE" \
  --admin-username "$VM_ADMIN_USER" \
  --admin-password "$VM_ADMIN_PASSWORD" \
  --nics "$VM2_NIC_NAME" \
  --os-disk-size-gb "$VM_DISK_SIZE" \
  --storage-sku "$VM_DISK_TYPE" \
  --authentication-type password

echo -e "${CYAN}\nDeployment completed successfully!${NC}"
