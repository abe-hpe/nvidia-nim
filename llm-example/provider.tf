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
variable "nim_image" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "vtadmin" {
  name = "vtadmin"
}
