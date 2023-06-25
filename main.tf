data "azurerm_resource_group" "tf_lab" {
  name = "terraform_lab"
}

resource "azurerm_virtual_network" "security" {
  name                = "${var.network_name}_security_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    type = "hub"
  }
}

resource "azurerm_subnet" "fw_internal" {
  name                 = "${var.network_name}_fw_internal_subnet"
  resource_group_name  = data.azurerm_resource_group.tf_lab.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "fw_external" {
  name                 = "${var.network_name}_fw_external_subnet"
  resource_group_name  = data.azurerm_resource_group.tf_lab.name
  virtual_network_name = azurerm_virtual_network.security.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_virtual_network" "spoke_1" {
  name                = "${var.network_name}_spoke_1_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    type = "spoke"
  }
}

resource "azurerm_subnet" "spoke_1" {
  name                 = "${var.network_name}_spoke_1_subnet"
  resource_group_name  = data.azurerm_resource_group.tf_lab.name
  virtual_network_name = azurerm_virtual_network.spoke_1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_virtual_network" "spoke_2" {
  name                = "${var.network_name}_spoke_2_vnet"
  location            = data.azurerm_resource_group.tf_lab.location
  resource_group_name = data.azurerm_resource_group.tf_lab.name
  address_space       = ["10.2.0.0/16"]

  tags = {
    type = "spoke"
  }
}

resource "azurerm_subnet" "spoke_2" {
  name                 = "${var.network_name}_spoke_2_subnet"
  resource_group_name  = data.azurerm_resource_group.tf_lab.name
  virtual_network_name = azurerm_virtual_network.spoke_2.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_virtual_network_peering" "spoke_1_to_hub" {
  name                      = "spoke_1_to_hub"
  resource_group_name       = data.azurerm_resource_group.tf_lab.name
  virtual_network_name      = azurerm_virtual_network.spoke_1.name
  remote_virtual_network_id = azurerm_virtual_network.security.id

  triggers = {
    remote_address_space = join(",", azurerm_virtual_network.security.address_space)
  }
}

resource "azurerm_virtual_network_peering" "spoke_2_to_hub" {
  name                      = "spoke_2_to_hub"
  resource_group_name       = data.azurerm_resource_group.tf_lab.name
  virtual_network_name      = azurerm_virtual_network.spoke_2.name
  remote_virtual_network_id = azurerm_virtual_network.security.id

  triggers = {
    remote_address_space = join(",", azurerm_virtual_network.security.address_space)
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_1" {
  name                      = "hub_to_spoke_1"
  resource_group_name       = data.azurerm_resource_group.tf_lab.name
  virtual_network_name      = azurerm_virtual_network.security.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_1.id

  triggers = {
    remote_address_space = join(",", azurerm_virtual_network.spoke_1.address_space)
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_2" {
  name                      = "hub_to_spoke_2"
  resource_group_name       = data.azurerm_resource_group.tf_lab.name
  virtual_network_name      = azurerm_virtual_network.security.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_2.id

  triggers = {
    remote_address_space = join(",", azurerm_virtual_network.spoke_2.address_space)
  }
}