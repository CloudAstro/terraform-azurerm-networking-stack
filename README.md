<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
# ☁️ Azure Networking Stack (Terraform Module)

The **Azure Networking Stack** is a modular, production-ready Terraform configuration designed to provision and manage core networking infrastructure in Microsoft Azure. It supports a range of networking components including virtual networks, subnets, route tables, network security groups (NSGs), and virtual network peerings. Each component is implemented as a reusable child module, enabling scalable and consistent deployments across environments. This stack is ideal for teams looking to automate Azure network provisioning with flexibility, compliance, and clarity.

---

## 🚀 What Does It Deploy?

| Component                         | Description                                                                 |
|----------------------------------|-----------------------------------------------------------------------------|
| 🔷 Virtual Network               | Configurable VNet with DNS, address space, edge zone, diagnostics, etc.     |
| 🔶 Subnets                      | Custom subnets with service endpoints, delegation, and policy controls      |
| 🚦 Route Tables                 | Custom routes, BGP propagation, and subnet association                      |
| 🔐 Network Security Groups (NSGs) | Inbound/outbound rules, metrics, logs, and per-subnet NSG assignment        |     |

---

## 🛠️ Implementation Notes
- Uses CloudAstro Terraform modules for core infrastructure.
- Tags for Subnets are not supported yet.
- Diagnostic settings are supported across all components.

## 🗺️ Azure Networking Stack Architecture Diagram (Peering Connection Setup)

This diagram illustrates a modular Terraform design for provisioning multiple Azure Virtual Networks (VNets) with VNet peering. Each VNet includes its own subnets, with optional NSGs and Route Tables. The architecture highlights how modules are composed to enable flexible, scalable network topologies and how peerings are established between VNets for secure interconnectivity.

![Azure Networking Stack Architecture Diagram](./examples/full/azure\_networking\_stack\_full.png)

## Example Usage

This example demonstrates how to provision subnets including route tables and default network security group within a virtual network, each with its specific configurations and optional delegations.

```hcl
resource "azurerm_resource_group" "this" {
  name     = "azure-network-stack"
  location = "germanywestcentral"
}

module "virtual_network_hub" {
  source = "../.."

  name                           = "vnet-hub"
  resource_group_name            = azurerm_resource_group.this.name
  address_space                  = ["10.1.0.0/16"]
  location                       = azurerm_resource_group.this.location
  dns_servers                    = ["168.63.129.16", "8.8.8.8"]
  flow_timeout_in_minutes        = 4
  private_endpoint_vnet_policies = "Disabled"

  subnets = {
    hub-subnet = {
      name                                          = "hub-subnet"
      address_prefixes                              = ["10.1.1.0/24"]
      default_outbound_access_enabled               = true
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = false
      service_endpoints                             = ["Microsoft.Storage", "Microsoft.Sql"]
      delegation = [
        {
          name = "delegation1"
          service_delegation = {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
      route_table = {
        name                          = "main-route-table"
        bgp_route_propagation_enabled = true
      }

      network_security_group = {
        name         = "web-nsg"

        security_rules = [
          {
            name                       = "allow-http"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "80"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            access                     = "Allow"
            priority                   = 100
            direction                  = "Inbound"
          },
          {
            name                       = "allow-https"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            access                     = "Allow"
            priority                   = 110
            direction                  = "Inbound"
          }
        ]
      }
    }
  }

  tags = {
    environment = "prod"
    team        = "networking"
  }
}

module "virtual_network_spoke" {
  source = "../.."

  name                           = "vnet-spoke"
  resource_group_name            = azurerm_resource_group.this.name
  address_space                  = ["10.2.0.0/16"]
  location                       = azurerm_resource_group.this.location
  dns_servers                    = ["168.63.129.16", "8.8.8.8"]
  flow_timeout_in_minutes        = 4
  private_endpoint_vnet_policies = "Disabled"

  subnets = {
    spoke-subnet = {
      name                                          = "spoke-subnet"
      address_prefixes                              = ["10.2.1.0/24"]
      default_outbound_access_enabled               = true
      private_endpoint_network_policies             = "Enabled"
      private_link_service_network_policies_enabled = false
      service_endpoints                             = ["Microsoft.Storage", "Microsoft.Sql"]
      delegation = [
        {
          name = "delegation1"
          service_delegation = {
            name    = "Microsoft.ContainerInstance/containerGroups"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      ]
      route_table = {
        name                          = "main-route-table"
        bgp_route_propagation_enabled = true

        routes = {
          route1 = {
            name                   = "route-to-internal"
            address_prefix         = "10.1.0.0/16"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.1.0.4"
          }

        }
      }

      network_security_group = {
        name         = "custom-web-nsg"

        security_rules = [
          {
            name                       = "allow-http"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "8080"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            access                     = "Allow"
            priority                   = 100
            direction                  = "Inbound"
          },
          {
            name                       = "allow-https"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "8443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
            access                     = "Allow"
            priority                   = 110
            direction                  = "Inbound"
          }
        ]
      }
    }
  }

  tags = {
    environment = "dev"
    team        = "networking"
  }
}

module "peering-hub-to-spoke" {
  source = "CloudAstro/virtual-network-peering/azurerm"

  name                                   = "vnet-hub-to-spoke"
  resource_group_name                    = azurerm_resource_group.this.name
  virtual_network_name                   = module.virtual_network_hub.virtual_network.name
  remote_virtual_network_id              = module.virtual_network_spoke.virtual_network.id
  peer_complete_virtual_networks_enabled = false
  local_subnet_names                     = [module.virtual_network_hub.subnets["hub-subnet"].name]
  remote_subnet_names                    = [module.virtual_network_spoke.subnets["spoke-subnet"].name]
  allow_virtual_network_access           = true
  allow_forwarded_traffic                = false
  allow_gateway_transit                  = false
  use_remote_gateways                    = false

}

module "peering-spoke-to-hub" {
  source = "CloudAstro/virtual-network-peering/azurerm"

  providers = {
    azurerm = azurerm.peer
  }

  name                                   = "vnet-spoke-to-hub"
  resource_group_name                    = azurerm_resource_group.this.name
  virtual_network_name                   = module.virtual_network_spoke.virtual_network.name
  remote_virtual_network_id              = module.virtual_network_hub.virtual_network.id
  peer_complete_virtual_networks_enabled = false
  local_subnet_names                     = [module.virtual_network_spoke.subnets["spoke-subnet"].name]
  remote_subnet_names                    = [module.virtual_network_hub.subnets["hub-subnet"].name]
  allow_virtual_network_access           = true
  allow_forwarded_traffic                = false
  allow_gateway_transit                  = false
  use_remote_gateways                    = false
}
```
<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0 |

<!-- markdownlint-disable MD013 -->

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | * `address_space` - (Required) The address space that is used the virtual network. You can supply more than one address space.<br/><br/>  Example input:<pre>address_space = ["10.10.0.0/16", "172.19.1.0/24" ]</pre> | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | * `location` - (Required) The location/region where the virtual network is created. Changing this forces a new resource to be created.<br/><br/>  Example input:<pre>location = "germanywestcentral"</pre> | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | * `name` - (Required) The name of the virtual network. Changing this forces a new resource to be created.<br/><br/>  Example input:<pre>name = "vnet-gwc-hub"</pre> | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | * `resource_group_name` - (Required) The name of the resource group in which to create the virtual network. Changing this forces a new resource to be created.<br/><br/>  Example input:<pre>resource_group_name = "rg-vnet-gwc-hub"</pre> | `string` | n/a | yes |
| <a name="input_bgp_community"></a> [bgp\_community](#input\_bgp\_community) | * `bgp_community` - (Optional) The BGP community attribute in format `<as-number>:<community-value>`.<br/><br/>-> **Note:** The `as-number` segment is the Microsoft ASN, which is always `12076` for now.<br/>  Example input:<pre>bgp_community = "<as-number>:<community-value>"</pre> | `string` | `null` | no |
| <a name="input_ddos_protection_plan"></a> [ddos\_protection\_plan](#input\_ddos\_protection\_plan) | * `ddos_protection_plan` - (Optional) A `ddos_protection_plan` block as documented below.<br/>A `ddos_protection_plan` block supports the following:<br/>  * `id` - (Required) The ID of DDoS Protection Plan.<br/>  * `enable` - (Required) Enable/disable DDoS Protection Plan on Virtual Network.<br/><br/>  Example input:<pre>ddos_protection_plan = {<br/>    id      = azurerm_network_ddos_protection_plan.resource.id<br/>    enable  = true<br/>  }</pre> | <pre>object({<br/>    enable = bool<br/>    id     = string<br/>  })</pre> | `null` | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | * `monitor_diagnostic_setting` - (Optional) The `monitor_diagnostic_setting` block resource as defined below.<br/>  * `name` - (Required) Specifies the name of the Diagnostic Setting. Changing this forces a new resource to be created.<br/><br/>  -> **Note:** If the name is set to 'service' it will not be possible to fully delete the diagnostic setting. This is due to legacy API support.<br/>  * `target_resource_id` - (Required) The ID of an existing Resource on which to configure Diagnostic Settings. Changing this forces a new resource to be created.<br/>  * `eventhub_name` - (Optional) Specifies the name of the Event Hub where Diagnostics Data should be sent.<br/><br/>  -> **Note:** If this isn't specified then the default Event Hub will be used.<br/>  * `eventhub_authorization_rule_id` - (Optional) Specifies the ID of an Event Hub Namespace Authorization Rule used to send Diagnostics Data.<br/><br/>  -> **Note:** This can be sourced from [the `azurerm_eventhub_namespace_authorization_rule` resource](eventhub\_namespace\_authorization\_rule.html) and is different from [a `azurerm_eventhub_authorization_rule` resource](eventhub\_authorization\_rule.html).<br/><br/>  -> **Note:** At least one of `eventhub_authorization_rule_id`, `log_analytics_workspace_id`, `partner_solution_id` and `storage_account_id` must be specified.<br/>  * `log_analytics_workspace_id` - (Optional) Specifies the ID of a Log Analytics Workspace where Diagnostics Data should be sent.<br/><br/>  -> **Note:** At least one of `eventhub_authorization_rule_id`, `log_analytics_workspace_id`, `partner_solution_id` and `storage_account_id` must be specified.<br/>  * `storage_account_id` - (Optional) The ID of the Storage Account where logs should be sent.<br/><br/>  -> **Note:** At least one of `eventhub_authorization_rule_id`, `log_analytics_workspace_id`, `partner_solution_id` and `storage_account_id` must be specified.<br/>  * `log_analytics_destination_type` - (Optional) Possible values are `AzureDiagnostics` and `Dedicated`. When set to `Dedicated`, logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy `AzureDiagnostics` table.<br/><br/>  -> **Note:** This setting will only have an effect if a `log_analytics_workspace_id` is provided. For some target resource type (e.g., Key Vault), this field is unconfigurable. Please see [resource types](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/azurediagnostics#resource-types) for services that use each method. Please [see the documentation](https://docs.microsoft.com/azure/azure-monitor/platform/diagnostic-logs-stream-log-store#azure-diagnostics-vs-resource-specific) for details on the differences between destination types.<br/>  * `partner_solution_id` - (Optional) The ID of the market partner solution where Diagnostics Data should be sent. For potential partner integrations, [click to learn more about partner integration](https://learn.microsoft.com/en-us/azure/partner-solutions/overview).<br/><br/>  -> **Note:** At least one of `eventhub_authorization_rule_id`, `log_analytics_workspace_id`, `partner_solution_id` and `storage_account_id` must be specified.<br/>  * `enabled_log` - (Optional) One or more `enabled_log` blocks as defined below.<br/><br/>  -> **Note:** At least one `enabled_log` or `metric` block must be specified. At least one type of Log or Metric must be enabled.<br/>  * `metric` - (Optional) One or more `metric` blocks as defined below.<br/><br/>  -> **Note:** At least one `enabled_log` or `metric` block must be specified.<br/><br/>An `enabled_log` block supports the following:<br/>  * `category` - (Optional) The name of a Diagnostic Log Category for this Resource.<br/><br/>  -> **Note:** The Log Categories available vary depending on the Resource being used. You may wish to use [the `azurerm_monitor_diagnostic_categories` Data Source](../d/monitor\_diagnostic\_categories.html) or [list of service specific schemas](https://docs.microsoft.com/azure/azure-monitor/platform/resource-logs-schema#service-specific-schemas) to identify which categories are available for a given Resource.<br/>  * `category_group` - (Optional) The name of a Diagnostic Log Category Group for this Resource.<br/><br/>  -> **Note:** Not all resources have category groups available.<br/><br/>  -> **Note:** Exactly one of `category` or `category_group` must be specified.<br/><br/>A `metric` block supports the following:<br/>  * `category` - (Required) The name of a Diagnostic Metric Category for this Resource.<br/><br/>  -> **Note:** The Metric Categories available vary depending on the Resource being used. You may wish to use [the `azurerm_monitor_diagnostic_categories` Data Source](../d/monitor\_diagnostic\_categories.html) to identify which categories are available for a given Resource.<br/>  * `enabled` - (Optional) Is this Diagnostic Metric enabled? Defaults to `true`.<br/><br/>The `timeouts` block allows you to specify [timeouts](https://www.terraform.io/language/resources/syntax#operation-timeouts) for certain actions:<br/>  * `create` - (Defaults to 30 minutes) Used when creating the Diagnostics Setting.<br/>  * `update` - (Defaults to 30 minutes) Used when updating the Diagnostics Setting.<br/>  * `read` - (Defaults to 5 minutes) Used when retrieving the Diagnostics Setting.<br/>  * `delete` - (Defaults to 60 minutes) Used when deleting the Diagnostics Setting.<br/><br/>  Example Input:<pre>diagnostic_settings = {<br/>   "vnet-diagnostic" = {<br/>    name                           = "vnet-diagnostic-setting"<br/>    target_resource_id             = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/virtualNetworks/<vnet-name>"<br/>    eventhub_name                  = null<br/>    eventhub_authorization_rule_id = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.EventHub/namespaces/<eventhub-namespace>/authorizationRules/<auth-rule-name>"<br/>    log_analytics_workspace_id     = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.OperationalInsights/workspaces/<workspace-name>"<br/>    storage_account_id             = "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>"<br/>    log_analytics_destination_type = "AzureDiagnostics"<br/>    partner_solution_id            = null<br/>      enabled_log = [<br/>        {<br/>          category       = "VirtualNetworkGatewayLogs"<br/>          category_group = null<br/>        },<br/>        {<br/>          category       = "FlowLogs"<br/>          category_group = null<br/>        }<br/>      ]<br/>      metric = {<br/>        category = "AllMetrics"<br/>        enabled  = true<br/>      }<br/>    }<br/>  }</pre> | <pre>map(object({<br/>    name                           = string<br/>    target_resource_id             = optional(string)<br/>    eventhub_name                  = optional(string)<br/>    eventhub_authorization_rule_id = optional(string)<br/>    log_analytics_workspace_id     = optional(string)<br/>    storage_account_id             = optional(string)<br/>    log_analytics_destination_type = optional(string)<br/>    partner_solution_id            = optional(string)<br/>    enabled_log = optional(set(object({<br/>      category       = optional(string)<br/>      category_group = optional(string)<br/>    })))<br/>    metric = optional(set(object({<br/>      category = string<br/>      enabled  = optional(bool, true)<br/>    })))<br/>    timeouts = optional(object({<br/>      create = optional(string, "30")<br/>      update = optional(string, "30")<br/>      read   = optional(string, "5")<br/>      delete = optional(string, "60")<br/>    }))<br/>  }))</pre> | `null` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | * `dns_servers` - (Optional) List of IP addresses of DNS servers<br/><br/>-> **Note:** Since `dns_servers` can be configured both inline and via the separate `azurerm_virtual_network_dns_servers` resource, we have to explicitly set it to empty slice (`[]`) to remove it.<br/><br/>  Example input:<pre>dns_servers = ["1.1.1.1", "8.8.8.8"]</pre> | `list(string)` | `[]` | no |
| <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone) | * `edge_zone` - (Optional) Specifies the Edge Zone within the Azure Region where this Virtual Network should exist. Changing this forces a new Virtual Network to be created.<br/><br/>  Example input:<pre>edge_zone = "attatlanta1" # AT&T</pre> | `string` | `null` | no |
| <a name="input_encryption"></a> [encryption](#input\_encryption) | * `encryption` - (Optional) A `encryption` block as defined below.<br/>A `encryption` block supports the following:<br/>  * `enforcement` - (Required) Specifies if the encrypted Virtual Network allows VM that does not support encryption. Possible values are `DropUnencrypted` and `AllowUnencrypted`.<br/><br/>  -> **Note:** Currently `AllowUnencrypted` is the only supported value for the `enforcement` property as `DropUnencrypted` is not yet in public preview or general availability. Please see the [official documentation](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-encryption-overview#limitations) for more information.<br/><br/>  Example input:<pre>ddos_protection_plan = {<br/>    id      = azurerm_network_ddos_protection_plan.resource.id<br/>    enable  = true<br/>  }</pre> | <pre>object({<br/>    enforcement = optional(string, "AllowUnencrypted")<br/>  })</pre> | `null` | no |
| <a name="input_flow_timeout_in_minutes"></a> [flow\_timeout\_in\_minutes](#input\_flow\_timeout\_in\_minutes) | * `flow_timeout_in_minutes` - (Optional) The flow timeout in minutes for the Virtual Network, which is used to enable connection tracking for intra-VM flows. Possible values are between 4 and 30 minutes.<br/><br/>  Example input:<pre>flow_timeout_in_minutes = 10</pre> | `number` | `4` | no |
| <a name="input_private_endpoint_vnet_policies"></a> [private\_endpoint\_vnet\_policies](#input\_private\_endpoint\_vnet\_policies) | * `private_endpoint_vnet_policies` - (Optional) The Private Endpoint VNet Policies for the Virtual Network. Possible values are `Disabled` and `Basic`. Defaults to `Disabled`.<br/><br/>  Example input:<pre>private_endpoint_vnet_policies = "Disabled"</pre> | `string` | `"Disabled"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A map of subnet configurations, where each key represents a subnet identifier, and the value is an object defining the subnet's properties, optional route table, and optional network security group.<br/><br/>  Each object includes:<br/><br/>  * `name` - (Required) Name of the subnet. Changing this forces a new resource.<br/>  * `address_prefixes` - (Required) List of CIDR blocks that define the address space of the subnet.<br/>  * `default_outbound_access_enabled` - (Optional) Boolean to enable outbound internet access by default. Defaults to `true`.<br/>  * `private_endpoint_network_policies` - (Optional) Policy setting for private endpoints. Options: `Enabled`, `Disabled`, `NetworkSecurityGroupEnabled`, `RouteTableEnabled`. Defaults to `Disabled`.<br/>  * `private_link_service_network_policies_enabled` - (Optional) Boolean to enable/disable network policies for private link services. Defaults to `true`.<br/>  * `service_endpoints` - (Optional) Set of service endpoints to associate with the subnet (e.g., `Microsoft.Sql`, `Microsoft.Storage`).<br/>  * `service_endpoint_policy_ids` - (Optional) Set of resource IDs for Service Endpoint Policies to associate with the subnet.<br/>  * `delegation` - (Optional) List of delegation blocks to assign services to the subnet.<br/>    * `name` - (Required) Name of the delegation.<br/>    * `service_delegation` - (Optional) Block specifying the delegated service:<br/>      * `name` - (Required) Name of the service to delegate (e.g., `Microsoft.ContainerInstance/containerGroups`).<br/>      * `actions` - (Optional) Set of delegated action strings.<br/><br/>  Example:<pre>subnets = {<br/>    my-subnet = {<br/>      name = "subnet1"<br/>      address_prefixes = ["10.1.1.0/24"]<br/>      delegation = [<br/>        {<br/>          name = "delegation1"<br/>          service_delegation = {<br/>            name    = "Microsoft.ContainerInstance/containerGroups"<br/>            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]<br/>          }<br/>        }<br/>      ]<br/>    }<br/>  }</pre>* `route_tables` - (Optional) Object defining a route table to associate with the subnet:<br/>    * `name` - (Required) Name of the route table.<br/>    * `bgp_route_propagation_enabled` - (Optional) Enable BGP route propagation. Defaults to `true`.<br/>    * `timeouts` - (Optional) Operation timeouts for managing the route table.<br/>      * `create` - Time allowed to create the route table.<br/>      * `read` - Time allowed to read the route table.<br/>      * `update` - Time allowed to update the route table.<br/>      * `delete` - Time allowed to delete the route table.<br/>    * `routes` - (Required) Map of custom routes to include:<br/>      * `name` - (Optional) Name of the route.<br/>      * `resource_group_name` - (Optional) Resource group name, if different from the default.<br/>      * `route_table_name` - (Optional) Name of the route table to reference.<br/>      * `address_prefix` - (Required) CIDR address range the route applies to.<br/>      * `next_hop_type` - (Required) Type of next hop (`VirtualAppliance`, `Internet`, etc.).<br/>      * `next_hop_in_ip_address` - (Optional) IP address of the next hop, used with `VirtualAppliance`.<br/>      * `timeouts` - (Optional) Timeouts for the individual route.<br/>        * `create`, `read`, `update`, `delete` - Duration strings.<br/>      * `tags` - (Optional) Map of custom tags for the route.<br/><br/>    * `management_lock` - (Optional) Map of management lock settings to protect the route table from accidental deletion or changes:<br/>      * `name` - (Required) Name of the lock.<br/>      * `scope` - (Optional) Scope at which the lock applies.<br/>      * `lock_level` - (Required) Lock level. Valid values: `CanNotDelete`, `ReadOnly`.<br/>      * `notes` - (Optional) Additional notes about the lock.<br/>      * `timeouts` - (Optional) Timeouts for lock resource management.<br/><br/>    * `tags` - (Optional) Map of key-value tags to apply to the route table.<br/><br/>  Example:<pre>route_table = {<br/>    name = "main-rt"<br/>    bgp_route_propagation_enabled = true<br/>    routes = {<br/>      internal = {<br/>        address_prefix = "10.0.0.0/16"<br/>        next_hop_type  = "VnetLocal"<br/>      }<br/>    }<br/>  }</pre>* `network_security_group` - (Optional) Object describing an NSG to associate with the subnet:<br/>    * `name` - (Required) Name of the NSG.<br/>    * `security_rules` - (Optional) List of security rules to define within the NSG:<br/>      * `name` - (Required) Name of the rule.<br/>      * `description` - (Optional) Description of the rule.<br/>      * `protocol` - (Required) Network protocol (`Tcp`, `Udp`, `Icmp`, `*`).<br/>      * `source_port_range` - (Optional) Source port range.<br/>      * `source_port_ranges` - (Optional) List of source port ranges.<br/>      * `destination_port_range` - (Optional) Destination port range.<br/>      * `destination_port_ranges` - (Optional) List of destination port ranges.<br/>      * `source_address_prefix` - (Optional) Source address prefix (e.g., `10.0.0.0/24`).<br/>      * `source_address_prefixes` - (Optional) List of source address prefixes.<br/>      * `destination_address_prefix` - (Optional) Destination address prefix.<br/>      * `destination_address_prefixes` - (Optional) List of destination address prefixes.<br/>      * `source_application_security_group_ids` - (Optional) Set of source ASG IDs.<br/>      * `destination_application_security_group_ids` - (Optional) Set of destination ASG IDs.<br/>      * `access` - (Required) Access type: `Allow` or `Deny`.<br/>      * `priority` - (Required) Rule priority. Lower numbers are evaluated first.<br/>      * `direction` - (Required) Direction of the rule: `Inbound` or `Outbound`.<br/><br/>    * `diagnostic_settings` - (Optional) Map of diagnostic settings for the NSG:<br/>      * `name` - (Required) Name of the diagnostic setting.<br/>      * `target_resource_id` - (Optional) Resource ID of the NSG.<br/>      * `eventhub_name` - (Optional) Name of the Event Hub to send diagnostics to.<br/>      * `eventhub_authorization_rule_id` - (Optional) Authorization rule ID for Event Hub.<br/>      * `log_analytics_workspace_id` - (Optional) ID of Log Analytics workspace.<br/>      * `storage_account_id` - (Optional) ID of a Storage Account for diagnostic logs.<br/>      * `log_analytics_destination_type` - (Optional) Destination type (e.g., `Dedicated`).<br/>      * `partner_solution_id` - (Optional) Optional partner solution integration ID.<br/>      * `enabled_log` - (Optional) Set of logs to enable:<br/>        * `category` - (Optional) Log category (e.g., `NetworkSecurityGroupEvent`).<br/>        * `category_group` - (Optional) Group of categories.<br/>      * `timeouts` - (Optional) Timeouts for diagnostics operations.<br/><br/>    * `timeouts` - (Optional) Timeout settings for NSG create, read, update, and delete.<br/>    * `tags` - (Optional) Map of custom tags for the NSG.<br/><br/>  Example:<pre>network_security_group = {<br/>    name = "subnet1-nsg"<br/>    security_rules = [<br/>      {<br/>        name                       = "allow-ssh"<br/>        protocol                   = "Tcp"<br/>        source_address_prefix      = "*"<br/>        destination_port_range     = "22"<br/>        access                     = "Allow"<br/>        priority                   = 100<br/>        direction                  = "Inbound"<br/>      }<br/>    ]<br/>  }</pre>* `timeouts` - (Optional) Operation timeouts for managing the subnet:<br/>    * `create`, `read`, `update`, `delete` - Duration strings (e.g., `"30m"`). | <pre>map(object({<br/>    name                                          = string<br/>    address_prefixes                              = list(string)<br/>    default_outbound_access_enabled               = optional(bool, true)<br/>    private_endpoint_network_policies             = optional(string, "Disabled")<br/>    private_link_service_network_policies_enabled = optional(bool, true)<br/>    service_endpoints                             = optional(set(string))<br/>    service_endpoint_policy_ids                   = optional(set(string))<br/>    delegation = optional(list(object({<br/>      name = string<br/>      service_delegation = optional(object({<br/>        name    = string<br/>        actions = set(string)<br/>      }))<br/>    })))<br/>    route_table = optional(object({<br/>      name                          = string<br/>      bgp_route_propagation_enabled = optional(bool, true)<br/>      timeouts = optional(object({<br/>        create = string<br/>        read   = string<br/>        update = string<br/>        delete = string<br/>      }))<br/>      routes = optional(map(object({<br/>        name                   = optional(string)<br/>        resource_group_name    = optional(string)<br/>        route_table_name       = optional(string)<br/>        address_prefix         = string<br/>        next_hop_type          = string<br/>        next_hop_in_ip_address = optional(string)<br/>        timeouts = optional(object({<br/>          create = optional(string, "30")<br/>          update = optional(string, "30")<br/>          read   = optional(string, "5")<br/>          delete = optional(string, "30")<br/>        }))<br/>        tags = optional(map(string))<br/>      })))<br/>      management_lock = optional(map(object({<br/>        name       = string<br/>        scope      = optional(string)<br/>        lock_level = string<br/>        notes      = optional(string)<br/>        timeouts = optional(object({<br/>          create = optional(string, "30")<br/>          read   = optional(string, "5")<br/>          delete = optional(string, "30")<br/>        }))<br/>      })))<br/>      tags = optional(map(string))<br/>    }))<br/>    network_security_group = optional(object({<br/>      name = string<br/>      security_rules = optional(list(object({<br/>        name                                       = string<br/>        description                                = optional(string)<br/>        protocol                                   = string<br/>        source_port_range                          = optional(string)<br/>        source_port_ranges                         = optional(list(string))<br/>        destination_port_range                     = optional(string)<br/>        destination_port_ranges                    = optional(list(string))<br/>        source_address_prefix                      = optional(string)<br/>        source_address_prefixes                    = optional(list(string))<br/>        destination_address_prefix                 = optional(string)<br/>        destination_address_prefixes               = optional(list(string))<br/>        source_application_security_group_ids      = optional(set(string))<br/>        destination_application_security_group_ids = optional(set(string))<br/>        access                                     = string<br/>        priority                                   = number<br/>        direction                                  = string<br/>      })))<br/>      diagnostic_settings = optional(map(object({<br/>        name                           = string<br/>        target_resource_id             = optional(string)<br/>        eventhub_name                  = optional(string)<br/>        eventhub_authorization_rule_id = optional(string)<br/>        log_analytics_workspace_id     = optional(string)<br/>        storage_account_id             = optional(string)<br/>        log_analytics_destination_type = optional(string)<br/>        partner_solution_id            = optional(string)<br/>        enabled_log = optional(set(object({<br/>          category       = optional(string)<br/>          category_group = optional(string)<br/>        })))<br/>        timeouts = optional(object({<br/>          create = optional(string, "30")<br/>          update = optional(string, "30")<br/>          read   = optional(string, "5")<br/>          delete = optional(string, "60")<br/>        }))<br/>      })))<br/>      timeouts = optional(object({<br/>        create = optional(string, "30")<br/>        update = optional(string, "30")<br/>        read   = optional(string, "5")<br/>        delete = optional(string, "30")<br/>      }))<br/>      tags = optional(map(string))<br/>    }))<br/>    timeouts = optional(object({<br/>      create = string<br/>      read   = string<br/>      update = string<br/>      delete = string<br/>    }))<br/>  }))</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | * `tags` - (Optional) A mapping of tags to assign to the resource.<br/><br/>  Example input:<pre>tags = {<br/>    env     = prod<br/>    region  = gwc<br/>  }</pre> | `map(string)` | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | The `timeouts` block allows you to specify [timeouts](https://www.terraform.io/language/resources/syntax#operation-timeouts) for certain actions:<br/>  * `create` - (Defaults to 30 minutes) Used when creating the Subnet.<br/>  * `read` - (Defaults to 5 minutes) Used when retrieving the Subnet.<br/>  * `update` - (Defaults to 30 minutes) Used when updating the Subnet.<br/>  * `delete` - (Defaults to 30 minutes) Used when deleting the Subnet. | <pre>object({<br/>    create = optional(string, "30")<br/>    read   = optional(string, "5")<br/>    update = optional(string, "30")<br/>    delete = optional(string, "30")<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_security_group"></a> [network\_security\_group](#output\_network\_security\_group) | Example output for details of network security group:<pre>output "route_tables" {<br/>    value = module.azure_networking_stack.network_security_group<br/>  }</pre>Example output for specific subnet network security group id:<pre>output "nsg_id" {<br/>    value = module.azure_networking_stack.network_security_group["subnet1"].id<br/>  }</pre> |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | Example output for details of subnets:<pre>output "route_tables" {<br/>    value = module.azure_networking_stack.route_tables<br/>  }</pre>Example output for specific subnets route table id:<pre>output "route_table_id" {<br/>    value = module.azure_networking_stack.route_tables["subnet1"].id<br/>  }</pre> |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | Example output for details of subnets:<pre>output "vnet_subnets" {<br/>    value = module.module_name.subnets<br/>  }</pre>Example output for specific subnets id:<pre>output "subnet_id" {<br/>    value = module.azure_networking_stack.subnets["subnet1"].name<br/>  }</pre> |
| <a name="output_virtual_network"></a> [virtual\_network](#output\_virtual\_network) | * `id`- Resource ID of the virtual network<br/>  * `location` - Azure region of the virtual network<br/>  * `address_space` - Address space (CIDR blocks)<br/>  * `dns_servers` - Custom DNS servers, if any<br/><br/>  Example output for whole object:<pre>output "vnet" {<br/>    value = module.module_name.virtual_network<br/>  }</pre>Example output for ID of virtual network:<pre>output "vnet_id" {<br/>    value = module.module_name.virtual_network.id<br/>  }</pre> |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_azure_network_security_group"></a> [azure\_network\_security\_group](#module\_azure\_network\_security\_group) | CloudAstro/network-security-group/azurerm | n/a |
| <a name="module_azure_route_table"></a> [azure\_route\_table](#module\_azure\_route\_table) | CloudAstro/route-table/azurerm | n/a |
| <a name="module_azure_subnet"></a> [azure\_subnet](#module\_azure\_subnet) | CloudAstro/subnet/azurerm | n/a |
| <a name="module_azure_virtual_network"></a> [azure\_virtual\_network](#module\_azure\_virtual\_network) | CloudAstro/virtual-network/azurerm | n/a |

## 🙋 Support

Please open a GitHub issue or start a discussion if you encounter problems or would like to suggest improvements. Contributions are welcome!

## 🧾 License  

This module is released under the **Apache 2.0 License**. See the [LICENSE](./LICENSE) file for full details.
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->