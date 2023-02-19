subnet_params = {

  load_balancer = {
    vnet = "dmz"
    cidr = "10.2.10.0/24"
  } 

  vpn_access = {
    vnet = "dmz"
    cidr = "10.2.20.0/24"
  }

  vault = {
    vnet = "app"
    cidr = "10.3.10.0/24"
  }

  hosting = {
    vnet = "app"
    cidr = "10.3.20.0/24"
  }

  mysql = {
    vnet = "db"
    cidr = "10.4.10.0/24"
  }

  mariadb = {
    vnet = "db"
    cidr = "10.4.20.0/24"
  }

}

#supernet = "10.0.0.0/8"