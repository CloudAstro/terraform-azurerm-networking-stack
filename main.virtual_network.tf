module "azure_virtual_network" {
  source = "CloudAstro/virtual-network/azurerm"

  name                           = var.name
  resource_group_name            = var.resource_group_name
  address_space                  = var.address_space
  location                       = var.location
  bgp_community                  = var.bgp_community
  dns_servers                    = var.dns_servers
  edge_zone                      = var.edge_zone
  flow_timeout_in_minutes        = var.flow_timeout_in_minutes
  private_endpoint_vnet_policies = var.private_endpoint_vnet_policies
  ddos_protection_plan           = var.ddos_protection_plan
  encryption                     = var.encryption
  timeouts                       = var.timeouts
  diagnostic_settings            = var.diagnostic_settings
  tags                           = var.tags
}
