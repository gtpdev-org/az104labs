#!/bin/bash
# Deploy ARM template for networking resources

RESOURCE_GROUP="RG1-ARM"
LOCATION="eastus"
TEMPLATE_FILE="$(dirname "$0")/main.json"

az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters location="$LOCATION"
