# Microsoft Azure Cloud TF Lab

## Overview

This terraform plan builds a network in the microsoft azure cloud.

Use of this module/s will require setting up ms azure provider and azure-cli (along w/credentials setup etc) before running terraform init

### Network Structure

- Three-Tier Design w/ Hub VNET

1. `DMZ` Virtual Network
2. `App` Virtual Network
3. `Database` Virtual Network

- Using Network Security Groups to create isolation between vnets

1. All Spoke VNETs can receive traffic from the `Hub VNET`
2. `DMZ VNET` can send traffic to `App VNET` (via hairpin at `Hub VNET`). `DMV VNET` can receive inbound traffic from `App` or `Hub VNET`s only.
3. `App VNET` can send traffic to `DMZ` or `Database VNET`s and can receive inbound traffic from either of those VNETs (always utilizing hairpin at `Hub`).
4. `Database VNET` can only receive traffic from `App VNET` and can only send traffic to `App VNET` (by way of `Hub` hairpin).

- NSG Rules in lieu of defaults

1. This module uses the priority argument in NSG rules to override default rules allowing traffic from within VNET or through VNET peering.
2. Those same permissions are still in place but through manual TF plan instead of relying on Azure defaults.

- Resources Used

1. azurerm_resource_group
2. azurerm_virtual_network
3. azurerm_virtual_network_peering
4. azurerm_subnet
5. azurerm_route_table
6. azurerm_network_security_group
7. azurerm_network_security_group_association
8. azurerm_network_security_rule
9. azurerm_network_watcher
10. azurerm_storage_account
11. azurerm_network_watcher_flow_log