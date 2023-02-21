module "network" {
  source = "./module"
  #source = "github.com/ahmutysj3/trace-azure-tf"
  network_name = var.network_name
  supernet = var.supernet
  vnet_params = var.vnet_params
  subnet_params = var.subnet_params
}
