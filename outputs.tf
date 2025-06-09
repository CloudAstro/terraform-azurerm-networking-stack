output "virtual_network" {
  value = module.azure_virtual_network.virtual_network

  description = <<DESCRIPTION
  * `id`- Resource ID of the virtual network
  * `location` - Azure region of the virtual network
  * `address_space` - Address space (CIDR blocks)
  * `dns_servers` - Custom DNS servers, if any

  Example output for whole object:
  ```
  output "vnet" {
    value = module.module_name.virtual_network
  }
  ```

  Example output for ID of virtual network:
  ```
  output "vnet_id" {
    value = module.module_name.virtual_network.id
  }
  ```
  DESCRIPTION
}

output "subnets" {
  value = {
    for key, value in module.azure_subnet :
    key => value.subnet
  }

  description = <<DESCRIPTION
  Example output for details of subnets:
  ```
  output "vnet_subnets" {
    value = module.module_name.subnets
  }
  ```

  Example output for specific subnets id:
  ```
  output "subnet_id" {
    value = module.azure_networking_stack.subnets["subnet1"].name
  }
  ```
  DESCRIPTION
}

output "route_tables" {
  value = {
    for key, value in module.azure_route_table :
    key => value.route_table
  }

  description = <<DESCRIPTION
  Example output for details of subnets:
  ```
  output "route_tables" {
    value = module.azure_networking_stack.route_tables
  }
  ```

  Example output for specific subnets route table id:
  ```
  output "route_table_id" {
    value = module.azure_networking_stack.route_tables["subnet1"].id
  }
  ```
  DESCRIPTION
}

output "network_security_group" {
  value = {
    for key, value in module.azure_network_security_group :
    key => value.nsg
  }

  description = <<DESCRIPTION
  Example output for details of network security group:
  ```
  output "route_tables" {
    value = module.azure_networking_stack.network_security_group
  }
  ```

  Example output for specific subnet network security group id:
  ```
  output "nsg_id" {
    value = module.azure_networking_stack.network_security_group["subnet1"].id
  }
  ```
  DESCRIPTION
}
