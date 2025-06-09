variable "subnets" {
  type = map(object({
    name                                          = string
    address_prefixes                              = list(string)
    default_outbound_access_enabled               = optional(bool, true)
    private_endpoint_network_policies             = optional(string, "Disabled")
    private_link_service_network_policies_enabled = optional(bool, true)
    service_endpoints                             = optional(set(string))
    service_endpoint_policy_ids                   = optional(set(string))
    delegation = optional(list(object({
      name = string
      service_delegation = optional(object({
        name    = string
        actions = set(string)
      }))
    })))
    route_table = optional(object({
      name                          = string
      bgp_route_propagation_enabled = optional(bool, true)
      timeouts = optional(object({
        create = string
        read   = string
        update = string
        delete = string
      }))
      routes = optional(map(object({
        name                   = optional(string)
        resource_group_name    = optional(string)
        route_table_name       = optional(string)
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string)
        timeouts = optional(object({
          create = optional(string, "30")
          update = optional(string, "30")
          read   = optional(string, "5")
          delete = optional(string, "30")
        }))
        tags = optional(map(string))
      })))
      management_lock = optional(map(object({
        name       = string
        scope      = optional(string)
        lock_level = string
        notes      = optional(string)
        timeouts = optional(object({
          create = optional(string, "30")
          read   = optional(string, "5")
          delete = optional(string, "30")
        }))
      })))
      tags = optional(map(string))
    }))
    network_security_group = optional(object({
      name = string
      security_rules = optional(list(object({
        name                                       = string
        description                                = optional(string)
        protocol                                   = string
        source_port_range                          = optional(string)
        source_port_ranges                         = optional(list(string))
        destination_port_range                     = optional(string)
        destination_port_ranges                    = optional(list(string))
        source_address_prefix                      = optional(string)
        source_address_prefixes                    = optional(list(string))
        destination_address_prefix                 = optional(string)
        destination_address_prefixes               = optional(list(string))
        source_application_security_group_ids      = optional(set(string))
        destination_application_security_group_ids = optional(set(string))
        access                                     = string
        priority                                   = number
        direction                                  = string
      })))
      diagnostic_settings = optional(map(object({
        name                           = string
        target_resource_id             = optional(string)
        eventhub_name                  = optional(string)
        eventhub_authorization_rule_id = optional(string)
        log_analytics_workspace_id     = optional(string)
        storage_account_id             = optional(string)
        log_analytics_destination_type = optional(string)
        partner_solution_id            = optional(string)
        enabled_log = optional(set(object({
          category       = optional(string)
          category_group = optional(string)
        })))
        timeouts = optional(object({
          create = optional(string, "30")
          update = optional(string, "30")
          read   = optional(string, "5")
          delete = optional(string, "60")
        }))
      })))
      timeouts = optional(object({
        create = optional(string, "30")
        update = optional(string, "30")
        read   = optional(string, "5")
        delete = optional(string, "30")
      }))
      tags = optional(map(string))
    }))
    timeouts = optional(object({
      create = string
      read   = string
      update = string
      delete = string
    }))
  }))
  default = null

  description = <<DESCRIPTION
  A map of subnet configurations, where each key represents a subnet identifier, and the value is an object defining the subnet's properties, optional route table, and optional network security group.

  Each object includes:

  * `name` - (Required) Name of the subnet. Changing this forces a new resource.
  * `address_prefixes` - (Required) List of CIDR blocks that define the address space of the subnet.
  * `default_outbound_access_enabled` - (Optional) Boolean to enable outbound internet access by default. Defaults to `true`.
  * `private_endpoint_network_policies` - (Optional) Policy setting for private endpoints. Options: `Enabled`, `Disabled`, `NetworkSecurityGroupEnabled`, `RouteTableEnabled`. Defaults to `Disabled`.
  * `private_link_service_network_policies_enabled` - (Optional) Boolean to enable/disable network policies for private link services. Defaults to `true`.
  * `service_endpoints` - (Optional) Set of service endpoints to associate with the subnet (e.g., `Microsoft.Sql`, `Microsoft.Storage`).
  * `service_endpoint_policy_ids` - (Optional) Set of resource IDs for Service Endpoint Policies to associate with the subnet.
  * `delegation` - (Optional) List of delegation blocks to assign services to the subnet.
    * `name` - (Required) Name of the delegation.
    * `service_delegation` - (Optional) Block specifying the delegated service:
      * `name` - (Required) Name of the service to delegate (e.g., `Microsoft.ContainerInstance/containerGroups`).
      * `actions` - (Optional) Set of delegated action strings.

  Example:
  ```
  subnets = {
    my-subnet = {
      name = "subnet1"
      address_prefixes = ["10.1.1.0/24"]
      delegation = [
        {
          name = "delegation1"
          service_delegation = {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
    }
  }
  ```

  * `route_tables` - (Optional) Object defining a route table to associate with the subnet:
    * `name` - (Required) Name of the route table.
    * `bgp_route_propagation_enabled` - (Optional) Enable BGP route propagation. Defaults to `true`.
    * `timeouts` - (Optional) Operation timeouts for managing the route table.
      * `create` - Time allowed to create the route table.
      * `read` - Time allowed to read the route table.
      * `update` - Time allowed to update the route table.
      * `delete` - Time allowed to delete the route table.
    * `routes` - (Required) Map of custom routes to include:
      * `name` - (Optional) Name of the route.
      * `resource_group_name` - (Optional) Resource group name, if different from the default.
      * `route_table_name` - (Optional) Name of the route table to reference.
      * `address_prefix` - (Required) CIDR address range the route applies to.
      * `next_hop_type` - (Required) Type of next hop (`VirtualAppliance`, `Internet`, etc.).
      * `next_hop_in_ip_address` - (Optional) IP address of the next hop, used with `VirtualAppliance`.
      * `timeouts` - (Optional) Timeouts for the individual route.
        * `create`, `read`, `update`, `delete` - Duration strings.
      * `tags` - (Optional) Map of custom tags for the route.

    * `management_lock` - (Optional) Map of management lock settings to protect the route table from accidental deletion or changes:
      * `name` - (Required) Name of the lock.
      * `scope` - (Optional) Scope at which the lock applies.
      * `lock_level` - (Required) Lock level. Valid values: `CanNotDelete`, `ReadOnly`.
      * `notes` - (Optional) Additional notes about the lock.
      * `timeouts` - (Optional) Timeouts for lock resource management.

    * `tags` - (Optional) Map of key-value tags to apply to the route table.

  Example:
  ```
  route_table = {
    name = "main-rt"
    bgp_route_propagation_enabled = true
    routes = {
      internal = {
        address_prefix = "10.0.0.0/16"
        next_hop_type  = "VnetLocal"
      }
    }
  }
  ```

  * `network_security_group` - (Optional) Object describing an NSG to associate with the subnet:
    * `name` - (Required) Name of the NSG.
    * `security_rules` - (Optional) List of security rules to define within the NSG:
      * `name` - (Required) Name of the rule.
      * `description` - (Optional) Description of the rule.
      * `protocol` - (Required) Network protocol (`Tcp`, `Udp`, `Icmp`, `*`).
      * `source_port_range` - (Optional) Source port range.
      * `source_port_ranges` - (Optional) List of source port ranges.
      * `destination_port_range` - (Optional) Destination port range.
      * `destination_port_ranges` - (Optional) List of destination port ranges.
      * `source_address_prefix` - (Optional) Source address prefix (e.g., `10.0.0.0/24`).
      * `source_address_prefixes` - (Optional) List of source address prefixes.
      * `destination_address_prefix` - (Optional) Destination address prefix.
      * `destination_address_prefixes` - (Optional) List of destination address prefixes.
      * `source_application_security_group_ids` - (Optional) Set of source ASG IDs.
      * `destination_application_security_group_ids` - (Optional) Set of destination ASG IDs.
      * `access` - (Required) Access type: `Allow` or `Deny`.
      * `priority` - (Required) Rule priority. Lower numbers are evaluated first.
      * `direction` - (Required) Direction of the rule: `Inbound` or `Outbound`.

    * `diagnostic_settings` - (Optional) Map of diagnostic settings for the NSG:
      * `name` - (Required) Name of the diagnostic setting.
      * `target_resource_id` - (Optional) Resource ID of the NSG.
      * `eventhub_name` - (Optional) Name of the Event Hub to send diagnostics to.
      * `eventhub_authorization_rule_id` - (Optional) Authorization rule ID for Event Hub.
      * `log_analytics_workspace_id` - (Optional) ID of Log Analytics workspace.
      * `storage_account_id` - (Optional) ID of a Storage Account for diagnostic logs.
      * `log_analytics_destination_type` - (Optional) Destination type (e.g., `Dedicated`).
      * `partner_solution_id` - (Optional) Optional partner solution integration ID.
      * `enabled_log` - (Optional) Set of logs to enable:
        * `category` - (Optional) Log category (e.g., `NetworkSecurityGroupEvent`).
        * `category_group` - (Optional) Group of categories.
      * `timeouts` - (Optional) Timeouts for diagnostics operations.

    * `timeouts` - (Optional) Timeout settings for NSG create, read, update, and delete.
    * `tags` - (Optional) Map of custom tags for the NSG.

  Example:
  ```
  network_security_group = {
    name = "subnet1-nsg"
    security_rules = [
      {
        name                       = "allow-ssh"
        protocol                   = "Tcp"
        source_address_prefix      = "*"
        destination_port_range     = "22"
        access                     = "Allow"
        priority                   = 100
        direction                  = "Inbound"
      }
    ]
  }
  ```

  * `timeouts` - (Optional) Operation timeouts for managing the subnet:
    * `create`, `read`, `update`, `delete` - Duration strings (e.g., `"30m"`).

  DESCRIPTION
}
