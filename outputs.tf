output "vnets" {
  value = {for k,v in azurerm_virtual_network.trace : v.name => v.id}
}

output "hub_peering" {
  value = {for k,v in azurerm_virtual_network_peering.hub : v.name => v.id}
}

output "spokes_peering" {
  value = {for k,v in azurerm_virtual_network_peering.spokes : v.name => v.id}
}

output "hub_subnet_cidr" {
  value = merge(
            { for k, v in azurerm_subnet.hub : 
                v.name => {
                    "cidr":element(v.address_prefixes,0), 
                    "vnet" : v.virtual_network_name,
                    "id" : v.id
                }
            },
            { for k, v in azurerm_subnet.spoke : 
                v.name => {
                    "cidr":element(v.address_prefixes,0), 
                    "vnet" : v.virtual_network_name,
                    "id" : v.id 
                }
            })
}