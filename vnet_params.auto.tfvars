subnet_params = {

  load_balancer = {
    vnet = "dmz"
    cidr = "10.2.10.0/24"
  } 

  vpn_access = {
    vnet = "dmz"
    cidr = "10.2.20.0/24"
  }

}

supernet = "10.0.0.0/8"