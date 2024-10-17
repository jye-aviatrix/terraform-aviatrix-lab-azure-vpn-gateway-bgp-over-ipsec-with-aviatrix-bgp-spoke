module "mc-transit" {
  source          = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version         = "2.5.3"
  cloud           = "azure"
  region          = var.region
  cidr            = "10.100.0.0/23"
  account         = var.aviatrix_access_account
  name            = "avx-transit"
  local_as_number = var.aviatrix_transit_asn
  resource_group  = azurerm_resource_group.this.name
  bgp_ecmp        = true
}

# Create a spoke and attach to transit
module "mc-spoke" {
  source         = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version        = "1.6.9"
  cloud          = "azure"
  region         = var.region
  cidr           = "10.200.1.0/24"
  account        = var.aviatrix_access_account
  name           = "avx-spoke"
  resource_group = azurerm_resource_group.this.name
  transit_gw     = module.mc-transit.transit_gateway.gw_name
}

module "azure-linux-vm-public-spoke-avx-1" {
  source              = "jye-aviatrix/azure-linux-vm-public/azure"
  version             = "3.0.1"
  public_key_file     = var.public_key_file
  region              = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.mc-spoke.vpc.public_subnets[1].subnet_id
  vm_name             = "avx-spoke-test-vm-1"
}

output "avx-spoke-test-vm-1" {
  value = module.azure-linux-vm-public-spoke-avx-1
}


# Create a spoke and attach to transit
module "mc-spoke-bgp" {
  source         = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version        = "1.6.9"
  cloud          = "azure"
  region         = var.region
  cidr           = "10.200.2.0/24"
  account        = var.aviatrix_access_account
  name           = "avx-spoke-bgp"
  resource_group = azurerm_resource_group.this.name
  transit_gw     = module.mc-transit.transit_gateway.gw_name
  enable_bgp = true
  local_as_number = var.aviatrix_spoke_asn
  bgp_ecmp = true
}


module "azure-linux-vm-public-bgp-spoke-avx-1" {
  source              = "jye-aviatrix/azure-linux-vm-public/azure"
  version             = "3.0.1"
  public_key_file     = var.public_key_file
  region              = var.region
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.mc-spoke-bgp.vpc.public_subnets[1].subnet_id
  vm_name             = "avx-bgp-spoke-test-vm-1"
}

output "avx-bgp-spoke-test-vm-1" {
  value = module.azure-linux-vm-public-bgp-spoke-avx-1
}

resource "aviatrix_spoke_external_device_conn" "this" {
  vpc_id             = module.mc-spoke-bgp.vpc.vpc_id
  connection_name    = "${module.mc-spoke-bgp.spoke_gateway.gw_name}-to-${var.vng_name}"
  gw_name            = module.mc-spoke-bgp.spoke_gateway.gw_name
  connection_type    = "bgp"
  tunnel_protocol    = "IPsec"
  enable_ikev2       = true
  bgp_local_as_num   = module.mc-spoke-bgp.spoke_gateway.local_as_number
  bgp_remote_as_num  = var.vng_asn
  remote_gateway_ip  = join(",", flatten(azurerm_virtual_network_gateway.this.bgp_settings[*].peering_addresses[*].tunnel_ip_addresses))
  local_tunnel_cidr  = "${var.avx_primary_tunnel_ip}/30,${var.avx_ha_tunnel_ip}/30"
  remote_tunnel_cidr = "${var.vng_primary_tunnel_ip}/30,${var.vng_ha_tunnel_ip}/30"
  pre_shared_key     = random_string.psk.result
  custom_algorithms = false
}
