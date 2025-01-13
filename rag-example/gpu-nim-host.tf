resource "digitalocean_droplet" "gpuhost" {
  image = "gpu-h100x1-base"
  region = "tor1"
  size = "gpu-h100x1-80gb"

  #create one resource for each name in the gpuhost_names list
  count = length(var.gpuhost_names)
  name  = var.gpuhost_names[count.index]

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
      "export PATH=$PATH:/usr/bin; export DEBIAN_FRONTEND=noninteractive; export NGC_API_KEY=${var.ngc_api_key}"
    ]
  }
}

output "host_info" {value=[digitalocean_droplet.gpuhost[*].name,digitalocean_droplet.gpuhost[*].ipv4_address]}
