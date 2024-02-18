# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "AituRG.L3"
  location = "eastus"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "AituVnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "aitu_subnet" {
  name                 = "AituSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "aitu_public_ips" {
  count               = 4
  name                = "publicIP-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP_8080"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "aitu_docker_nic" {
  count               = 3
  name                = "dockernic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.aitu_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.aitu_public_ips.*.id, count.index)
  }
}

resource "azurerm_network_interface" "aitu_mongodb_nic" {
  name                = "mongodb-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.aitu_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.aitu_public_ips.*.id, 3)
  }
}

# Create network interface example of creating private IP (not necessary at the moment)
#resource "azurerm_network_interface" "aitu_db_nic" {
#  name                = "myNIC"
#  location            = azurerm_resource_group.rg.location
#  resource_group_name = azurerm_resource_group.rg.name

#  ip_configuration {
#    name                          = "my_nic_configuration"
#    subnet_id                     = azurerm_subnet.aitu_subnet.id
#    private_ip_address_allocation = "Dynamic"
#  }
#}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "private_key" {
  value     = tls_private_key.example_ssh.private_key_openssh
  sensitive = true
}

# bootstraping VM
data "template_file" "linux-docker-cloud-init" {
  template = file("azure-docker-data.sh")
}
# bootstraping VM
data "template_file" "linux-dataabase-cloud-init" {
  template = file("azure-database-data.sh")
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "docker-master" {
  count                 = 3
  name                  = "docker-master-${count.index}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.aitu_docker_nic.*.id, count.index)]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "docker-master-disk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "docker-master-${count.index}"
  admin_username                  = "aitu"
  disable_password_authentication = true
  custom_data    = base64encode(data.template_file.linux-docker-cloud-init.rendered)

  admin_ssh_key {
    username   = "aitu"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }
}

resource "azurerm_linux_virtual_machine" "mongodb" {
  name                  = "mongodb"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.aitu_mongodb_nic.id]
  size                  = "Standard_B1s"

  os_disk {
    name                 = "docker-mongodb-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "docker-mongodb"
  admin_username                  = "aitu"
  disable_password_authentication = true
  custom_data    = base64encode(data.template_file.linux-dataabase-cloud-init.rendered)

  admin_ssh_key {
    username   = "aitu"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }
}