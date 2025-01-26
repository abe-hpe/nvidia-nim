resource "digitalocean_droplet" "gpuhost" {
  #image = "gpu-h100x1-base"
  image = "ubuntu-24-10-x64"
  region = "sfo3"
  #size = "gpu-h100x1-80gb"
  size = "s-1vcpu-512mb-10gb"

  #create one resource for each name in the gpuhost_names list
  for_each = toset( var.gpuhost_names )
  name = each.key

  ssh_keys = [
    data.digitalocean_ssh_key.vtadmin.id
  ]
  
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "5m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "echo ${var.ngc_api_key} > /root/ngc-api-key"
    ]
  }
}

resource "digitalocean_record" "endpoints" {
  domain = "quyver.com"
  type   = "A"
  ttl    = "300"
  for_each = digitalocean_droplet.gpuhost
  name   = each.value.name
  value  = each.value.ipv4_address
}


output "host_info" {
  value = {
    for host, values in digitalocean_droplet.gpuhost : host => values.ipv4_address
  }
}

