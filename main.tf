resource "azurerm_resource_group" "main" {
  name     = "trace_main_rg"
  location = var.azure_region
}