terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "shahal-x" {
  name     = "shahal-TerraformX"
  location = "West Europe"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "shahal-vn" {
  name                = "shahal-networkx"
  resource_group_name = azurerm_resource_group.shahal-x.name
  location            = azurerm_resource_group.shahal-x.location
  address_space       = ["10.125.0.0/16"]

  tags = {
    environment = "dev"
  }
}
resource "azurerm_subnet" "shahal-net" {
  name                 = "shahal-subnet"
  resource_group_name  = azurerm_resource_group.shahal-x.name
  virtual_network_name = azurerm_virtual_network.shahal-vn.name
  address_prefixes     = ["10.125.1.0/24"]
}

resource "azurerm_network_security_group" "s-group" {
  name                = "shahal-Sgroup"
  location            = azurerm_resource_group.shahal-x.location
  resource_group_name = azurerm_resource_group.shahal-x.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow_ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.s-group.name
  resource_group_name         = azurerm_resource_group.shahal-x.name
}



resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow_http"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.s-group.name
  resource_group_name         = azurerm_resource_group.shahal-x.name
}


resource "azurerm_subnet_network_security_group_association" "shahal-sga" {
  subnet_id                 = azurerm_subnet.shahal-net.id
  network_security_group_id = azurerm_network_security_group.s-group.id
}

resource "azurerm_public_ip" "shahal-ip" {
  name                = "shahal-ipx"
  location            = azurerm_resource_group.shahal-x.location
  resource_group_name = azurerm_resource_group.shahal-x.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "shahal-nic" {
  name                = "shahal-nicx"
  location            = azurerm_resource_group.shahal-x.location
  resource_group_name = azurerm_resource_group.shahal-x.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.shahal-net.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.shahal-ip.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "shahal-vm" {
  name                = "shahal-vmx"
  location            = azurerm_resource_group.shahal-x.location
  resource_group_name = azurerm_resource_group.shahal-x.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/azuresshkey.pub")
  }

  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.shahal-nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

}

output "public_ip" {
  value = azurerm_public_ip.shahal-ip.ip_address
}
