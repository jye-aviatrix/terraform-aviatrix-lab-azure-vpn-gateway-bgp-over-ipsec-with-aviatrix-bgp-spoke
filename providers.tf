terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.2.0"
    }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = "3.1.5"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configure Aviatrix provider
provider "aviatrix" {

}