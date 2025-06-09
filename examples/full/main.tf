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