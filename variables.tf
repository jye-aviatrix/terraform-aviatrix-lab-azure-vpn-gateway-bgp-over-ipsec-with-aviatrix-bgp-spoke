variable "resource_group_name" {
  type        = string
  description = "Provide Resource Group Name"
  default     = "lab-azure-vpn-gateway-bgp-over-ipsec-with-aviatrix-transit"
}

variable "region" {
  type        = string
  description = "Provide region of the resources"
  default     = "East US"
}

variable "tags" {
  type        = map(any)
  description = "Provide tags for resources"
  default = {
    Name = "lab-azure-vpn-gateway-bgp-over-ipsec-with-aviatrix-transit"
  }
}


variable "aviatrix_access_account" {
  type        = string
  description = "Provide Aviatrix Access Account name for the target Azure Subscription"
}

variable "aviatrix_transit_asn" {
  type        = number
  description = "Provide ASN for Aviatrix Transit"
  default     = 65001
}

variable "aviatrix_spoke_asn" {
  type        = number
  description = "Provide ASN for Aviatrix Transit"
  default     = 65002
}

variable "vng_name" {
  type        = string
  description = "Provide VNG name"
  default     = "vng"
}

variable "vng_asn" {
  type        = number
  description = "Provide ASN for Azure VPN Gateway"
  default     = 65010
}

variable "vng_primary_tunnel_ip" {
  type        = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default     = "169.254.21.1"
}

variable "vng_ha_tunnel_ip" {
  type        = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default     = "169.254.22.1"
}

variable "avx_primary_tunnel_ip" {
  type        = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default     = "169.254.21.2"
}

variable "avx_ha_tunnel_ip" {
  type        = string
  description = "In Azure it's called Custom Azure APIPA BGP IP address, must be in the range of 169.254.21.* and 169.254.22.*. In Aviatrix this is the /30 tunnel IP"
  default     = "169.254.22.2"
}

variable "public_key_file" {
  type        = string
  description = "Provide the path to the test instance's SSH public key"
}