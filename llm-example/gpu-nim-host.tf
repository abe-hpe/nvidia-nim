resource "digitalocean_droplet" "gpuhost" {
  image = "gpu-h100x1-base"
  name = "gpuhost"
  region = "tor1"
  size = "gpu-h100x1-80gb"
  ssh_keys = [
    data.digitalocean_ssh_key.vtadmin.id
  ]
  
  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key)
    timeout = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "apt-get update",
      "sleep 30",
      "apt-get install -y apt-transport-https ca-certificates curl gpg lsb-release",
      "curl -LO https://github.com/containerd/nerdctl/releases/download/v1.7.6/nerdctl-full-1.7.6-linux-amd64.tar.gz",
      "tar Cxzvvf /usr/local nerdctl-full-1.7.6-linux-amd64.tar.gz",
      "echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/custom.conf",
      "sysctl --system",
      "systemctl start containerd",
      "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list",
      "apt-get update && apt-get install -y nvidia-container-toolkit",
    ]
  }
}

output "host_ip_address" {value=digitalocean_droplet.gpuhost.ipv4_address}
