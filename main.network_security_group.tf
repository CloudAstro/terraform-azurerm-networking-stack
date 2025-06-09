module "azure_network_security_group" {
  source = "CloudAstro/network-security-group/azurerm"

  for_each = var.subnets != null ? { for key, value in var.subnets : key => value if value.network_security_group != null } : {}

  name                = each.value.network_security_group.name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = module.azure_subnet[each.key].subnet.id
  security_rules      = each.value.network_security_group.security_rules
  diagnostic_settings = each.value.network_security_group.diagnostic_settings
  timeouts            = each.value.network_security_group.timeouts
  tags                = each.value.network_security_group.tags
}
