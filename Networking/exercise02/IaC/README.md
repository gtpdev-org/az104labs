# Resource Specification
## 1. Virtual Network
- <code>app-vnet</code> (already defined)

## 2. Public IP Addresses
- <code>VM1-ip</code> (Static, Standard SKU)
- <code>VM2-ip</code> (Static, Standard SKU)

## 3. Network Interfaces
- VM1-nic
    - IP Configuration: <code>ipconfig1</code>
    - Private IP: Dynamic
    - Public IP: <code>VM1-ip</code>
    - Subnet: <code>frontend</code>
- VM2-nic
    - IP Configuration: <code>ipconfig1</code>
    - Private IP: Dynamic
    - Public IP: <code>VM2-ip</code>
    - Subnet: <code>backend</code>

## 4. Virtual Machines
- VM1
    - Size: <code>Standard_B1ls</code>
    - Image: UbuntuServer 24.04-LTS - x64 Gen2
    - OS Disk: 30GB, Standard_LRS, ReadWrite, Detach on delete
    - NIC: <code>VM1-nic</code>
- VM2
    - Size: <code>Standard_B1ls</code>
    - Image: UbuntuServer 24.04-LTS - x64 Gen2
    - OS Disk: 30GB, Standard_LRS, ReadWrite, Detach on delete
    - NIC: <code>VM2-nic</code>
