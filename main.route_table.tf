module "azure_route_table" {
  source = "CloudAstro/route-table/azurerm"

  for_each = var.subnets != null ? { for key, value in var.subnets : key => value if value.route_table != null } : {}

  name                          = each.value.route_table.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = module.azure_subnet[each.key].subnet.id
  bgp_route_propagation_enabled = each.value.route_table.bgp_route_propagation_enabled
  timeouts                      = each.value.route_table.timeouts
  routes                        = each.value.route_table.routes
  management_lock               = each.value.route_table.management_lock
  tags                          = each.value.route_table.tags
}