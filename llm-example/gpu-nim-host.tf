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
      "export PATH=$PATH:/usr/bin; export DEBIAN_FRONTEND=noninteractive; export NGC_API_KEY=${var.ngc_api_key}",
      "apt-get update",
      "sleep 30",
      "apt-get install -yq apt-transport-https ca-certificates curl gpg lsb-release unzip",
      "curl -LO https://github.com/containerd/nerdctl/releases/download/v1.7.6/nerdctl-full-1.7.6-linux-amd64.tar.gz",
      "tar Cxzvvf /usr/local nerdctl-full-1.7.6-linux-amd64.tar.gz",
      "echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/custom.conf",
      "sysctl --system",
      "systemctl start containerd",
      "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list",
      "apt-get update && apt-get install -yq nvidia-container-toolkit",
      "nerdctl run --rm --gpus all ubuntu nvidia-smi",
      "echo ${var.ngc_api_key} | docker login nvcr.io --username '$oauthtoken' --password-stdin",
      "curl -LO https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.54.0/files/ngccli_linux.zip",
      "unzip ngccli_linux.zip && chmod u+x ngc-cli/ngc && rm -rf ./ngccli_linux.zip",
      "./ngc-cli/ngc registry image list --format_type ascii nvcr.io/nim/*",
      "mkdir -p ~/.cache/nim",
      "nerdctl run -d --gpus all --shm-size=16GB --name myllama -e NGC_API_KEY -v ~/.cache/nim:/opt/nim/.cache -u 0 -p 8000:8000 nvcr.io/nim/meta/llama-3.1-8b-instruct:latest",
      "iptables -A CNI-FORWARD -p tcp -m tcp --dport 8000 -j ACCEPT",
    ]
  }
}

output "host_ip_address" {value=digitalocean_droplet.gpuhost.ipv4_address}
