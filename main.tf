data "azurerm_resource_group" "tf_lab" {
  name = "terraform_lab"
}

output "id" {
  value = data.azurerm_resource_group.tf_lab.id
}