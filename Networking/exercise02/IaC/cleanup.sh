#!/bin/bash

# cleanup.sh - Deletes all resource groups created by IaC scripts in this exercise01 directory.

set -euo pipefail

# Manually specify the resource group names to delete
RG_NAMES=("RG1-AzureCLI" "RG1-AzurePowerShell" "RG1-Bicep")

if [[ ${#RG_NAMES[@]} -eq 0 ]]; then
    echo "No resource groups specified."
    exit 0
fi

echo "The following resource groups will be deleted:"
echo "${RG_NAMES[@]}"
echo

read -p "Are you sure you want to delete these resource groups? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

for RG in "${RG_NAMES[@]}"; do
    echo "Deleting resource group: $RG"
    az group delete --name "$RG" --yes
done

echo "Resource groups deleted."