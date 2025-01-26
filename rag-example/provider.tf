terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}
variable "pvt_key" {}
variable "ngc_api_key" {}
variable "gpuhost_names" {
  description = "Names for the GPU hosts"
  type        = list(string)
}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "vtadmin" {
  name = "vtadmin"
}
