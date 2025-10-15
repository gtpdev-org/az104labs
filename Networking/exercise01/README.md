# Resource Specification

## 1. Resource Group
- **Name:** <code>RG1</code>
- **Location:** <code>eastus</code>

## 2. Virtual Networks
- **Hub VNet**
  - Name: <code>hub-vnet</code>
  - Address Prefix: <code>10.0.0.0/16</code>
  - Subnets:
    - **Firewall Subnet**
      - Name: <code>AzureFirewallSubnet</code>
      - Address Prefix: <code>10.0.0.0/26</code>
- **App VNet**
  - Name: <code>app-vnet</code>
  - Address Prefix: <code>10.1.0.0/16</code>
  - Subnets:
    - **Frontend Subnet**
      - Name: <code>frontend</code>
      - Address Prefix: <code>10.1.0.0/24</code>
    - **Backend Subnet**
      - Name: <code>backend</code>
      - Address Prefix: <code>10.1.1.0/24</code>

## 3. VNet Peerings
- **Hub-to-App Peering**
  - Name: <code>hub-to-app-vnet</code>
  - Source: <code>hub-vnet</code>
  - Remote: <code>app-vnet</code>
  - Allow Forwarded Traffic: <code>true</code>
- **App-to-Hub Peering**
  - Name: <code>app-vnet-to-hub</code>
  - Source: <code>app-vnet</code>
  - Remote: <code>hub-vnet</code>
  - Allow Forwarded Traffic: <code>true</code>