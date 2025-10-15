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
    - **Firewall Subnet**
      - Name: <code>AzureFirewallSubnet</code>
      - Address Prefix: <code>10.1.63.0/26</code>

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

## 4. Public IP Addresses
- **Virtual Machine 1**
    - Name: <code>VM1-ip</code>
    - Type: Static
    - Sku: Standard
- **Virtual Machine 2**
    - Name: <code>VM2-ip</code>
    - Type: Static
    - Sku: Standard

## 5. Network Interfaces
- **Virtual Machine 1**
    - Name: <code>VM1-nic</code>
    - IP Configuration: <code>ipconfig1</code>
    - Private IP: Dynamic
    - Public IP: <code>VM1-ip</code>
    - Subnet: <code>frontend</code>
- **Virtual Machine 2**
    - Name: <code>VM2-nic</code>
    - IP Configuration: <code>ipconfig1</code>
    - Private IP: Dynamic
    - Public IP: <code>VM2-ip</code>
    - Subnet: <code>backend</code>

## 6. Virtual Machines
- **Virtual Machine 1**
    - Name: <code>VM1</code>
    - Size: <code>Standard_B1ls</code>
    - Image: UbuntuServer 24.04-LTS - x64 Gen2
    - OS Disk: 
        - Size: <code>30GB</code>
        - Type: <code>Standard_LRS</code>
        - Caching: <code>ReadWrite</code>
        - Action: Detach on delete
    - NIC: <code>VM1-nic</code>
- **Virtual Machine 1**
    - Name: <code>VM2</code>
    - Size: <code>Standard_B1ls</code>
    - Image: UbuntuServer 24.04-LTS - x64 Gen2
    - OS Disk: 
        - Size: <code>30GB</code>
        - Type: <code>Standard_LRS</code>
        - Caching: <code>ReadWrite</code>
        - Action: Detach on delete
    - NIC: <code>VM2-nic</code>
