resource "azurerm_resource_group" "this" {
  name     = "azure-network-stack"
  location = "germanycentral"
}

module "azure_networking_stack" {
  source = "../.."

  name                           = "my-vnet"
  resource_group_name            = azurerm_resource_group.this.name
  address_space                  = ["10.1.0.0/16"]
  location                       = azurerm_resource_group.this.location
  dns_servers                    = ["168.63.129.16", "8.8.8.8"]
  flow_timeout_in_minutes        = 4
  private_endpoint_vnet_policies = "Disabled"

  subnets = {
    "subnet1" = {
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

        routes = {
          "route1" = {
            name                   = "route-to-internal"
            address_prefix         = "10.1.0.0/16"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.0.0.4"
          }
          "route2" = {
            address_prefix = "0.0.0.0/0"
            next_hop_type  = "Internet"
          }
        }
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
    environment = "dev"
    team        = "networking"
  }
}
