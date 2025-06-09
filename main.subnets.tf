module "azure_subnet" {
  source = "CloudAstro/subnet/azurerm"

  for_each = var.subnets != null ? var.subnets : {}

  name                                          = each.value.name
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = module.azure_virtual_network.virtual_network.name
  address_prefixes                              = each.value.address_prefixes
  default_outbound_access_enabled               = each.value.default_outbound_access_enabled
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoints                             = each.value.service_endpoints
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids
  delegation                                    = each.value.delegation
  timeouts                                      = each.value.timeouts
}
