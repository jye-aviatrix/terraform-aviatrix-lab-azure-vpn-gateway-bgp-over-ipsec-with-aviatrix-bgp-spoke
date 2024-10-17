# # Reference for creating VPN Gateway for site to site connection
# # https://learn.microsoft.com/en-us/azure/vpn-gateway/tutorial-site-to-site-portal


# Create parent Resource Group to house resources
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.region
  tags     = var.tags
}

# Create Virtual VPN Gateway's vNet
resource "azurerm_virtual_network" "vng_vnet" {
  name                = "vng-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.10.0/24"]
  tags                = var.tags
}

# Create Subnet for Virtual Private Gateway
resource "azurerm_subnet" "vng_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vng_vnet.name
  address_prefixes     = ["10.0.10.0/27"]
}

# # # Create Subnet for Test Instance

# # resource "azurerm_subnet" "test_subnet" {
# #   name                 = "test"
# #   resource_group_name  = azurerm_resource_group.this.name
# #   virtual_network_name = azurerm_virtual_network.vng_vnet.name
# #   address_prefixes     = ["10.0.10.32/27"]
# # }

# # # Create test instance
# # module "azure-linux-vm-public" {
# #   source              = "jye-aviatrix/azure-linux-vm-public/azure"
# #   version             = "3.0.1"
# #   public_key_file     = var.public_key_file
# #   region              = var.region
# #   resource_group_name = azurerm_resource_group.this.name
# #   subnet_id           = azurerm_subnet.test_subnet.id
# #   vm_name             = "vng-test-vm"
# # }

# # output "vng-test-vm" {
# #   value = module.azure-linux-vm-public
# # }


# Create vNet peering between VNG and Spoke Vnet
resource "azurerm_virtual_network_peering" "spoke_to_vng" {
  name                         = "spoke-to-vng"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.vng_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}

resource "azurerm_virtual_network_peering" "vng_to_spoke" {
  name                         = "vng-to-spoke"
  resource_group_name          = azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.vng_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    azurerm_virtual_network_gateway.this
  ]
}

# Create spoke vNet that will peer with VNG vNet
resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "spoke-network"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.20.0/24"]
  tags                = var.tags
}

# Create Subnet for Virtual Private Gateway
resource "azurerm_subnet" "spoke_subnet" {
  name                 = "spoke-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.0.20.0/27"]
}

module "azure-linux-vm-public-spoke-1" {
  source              = "jye-aviatrix/azure-linux-vm-public/azure"
  version             = "3.0.1"
  public_key_file     = var.public_key_file
  region              = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.spoke_subnet.id
  vm_name             = "spoke-test-vm-1"
}

output "spoke-test-vm-1" {
  value = module.azure-linux-vm-public-spoke-1
}

module "azure-linux-vm-public-spoke-2" {
  source              = "jye-aviatrix/azure-linux-vm-public/azure"
  version             = "3.0.1"
  public_key_file     = var.public_key_file
  region              = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.spoke_subnet.id
  vm_name             = "spoke-test-vm-2"
}

output "spoke-test-vm-2" {
  value = module.azure-linux-vm-public-spoke-2
}

# Create two public IPs for VNG
resource "azurerm_public_ip" "vng_pip_1" {
  name                = "vng-pip-1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_public_ip" "vng_pip_2" {
  name                = "vng-pip-2"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_virtual_network_gateway" "this" {
  name                = var.vng_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = true
  enable_bgp    = true
  sku           = "VpnGw2"

  generation = "Generation2"

  bgp_settings {
    asn         = var.vng_asn
    peer_weight = 0

    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig1"
      apipa_addresses       = [var.vng_primary_tunnel_ip]
    }
    peering_addresses {
      ip_configuration_name = "vnetGatewayConfig2"
      apipa_addresses       = [var.vng_ha_tunnel_ip]
    }
  }



  ip_configuration {
    name                          = "vnetGatewayConfig1"
    public_ip_address_id          = azurerm_public_ip.vng_pip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng_subnet.id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig2"
    public_ip_address_id          = azurerm_public_ip.vng_pip_2.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.vng_subnet.id
  }
}




# Create Preshared Key for IPSec tunnels
resource "random_string" "psk" {
  length  = 40
  special = false
}




resource "azurerm_local_network_gateway" "primary" {
  name                = module.mc-spoke-bgp.spoke_gateway.gw_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  gateway_address     = module.mc-spoke-bgp.spoke_gateway.eip
  bgp_settings {
    asn         = module.mc-spoke-bgp.spoke_gateway.local_as_number
    peer_weight = 0

    bgp_peering_address = var.avx_primary_tunnel_ip
  }
}

resource "azurerm_local_network_gateway" "ha" {
  name                = module.mc-spoke-bgp.spoke_gateway.ha_gw_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  gateway_address     = module.mc-spoke-bgp.spoke_gateway.ha_eip
  bgp_settings {
    asn         = module.mc-spoke-bgp.spoke_gateway.local_as_number
    peer_weight = 0

    bgp_peering_address = var.avx_ha_tunnel_ip
  }
}

resource "azurerm_virtual_network_gateway_connection" "primary" {
  name                = module.mc-spoke-bgp.spoke_gateway.gw_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.primary.id

  shared_key = random_string.psk.result
  enable_bgp = true
  ipsec_policy {
    ike_integrity    = "SHA256"
    ike_encryption   = "AES256"    
    dh_group         = "DHGroup14"
    ipsec_integrity  = "SHA256"
    ipsec_encryption = "AES256"    
    pfs_group        = "PFS2048" # Microsoft call phase 2 DH group 14 PFS2048 https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-compliance-crypto#which-diffie-hellman-groups-does-the-custom-policy-support
  }
  connection_mode = "ResponderOnly"

  custom_bgp_addresses {
    primary   = var.vng_primary_tunnel_ip
    secondary = var.vng_ha_tunnel_ip
  }
}

resource "azurerm_virtual_network_gateway_connection" "ha" {
  name                = module.mc-spoke-bgp.spoke_gateway.ha_gw_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.this.id
  local_network_gateway_id   = azurerm_local_network_gateway.ha.id

  shared_key = random_string.psk.result
  enable_bgp = true
  ipsec_policy {
    ike_integrity    = "SHA256"
    ike_encryption   = "AES256"    
    dh_group         = "DHGroup14"
    ipsec_integrity  = "SHA256"
    ipsec_encryption = "AES256"    
    pfs_group        = "PFS2048" # Microsoft call phase 2 DH group 14 PFS2048 https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-compliance-crypto#which-diffie-hellman-groups-does-the-custom-policy-support
  }
  connection_mode = "ResponderOnly"

  custom_bgp_addresses {
    primary   = var.vng_primary_tunnel_ip
    secondary = var.vng_ha_tunnel_ip
  }
}
