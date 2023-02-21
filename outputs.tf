output "vnets" {
  value = module.network.vnets
}

output "hub_peering" {
  value = module.network.hub_peering
}

output "spokes_peering" {
  value = module.network.spokes_peering
}

output "subnets" {
  value = module.network.subnets
}

output "hub_route_tables" {
  value = module.network.hub_route_tables
}

output "spokes_route_tables" {
  value = module.network.spokes_route_tables
} 
