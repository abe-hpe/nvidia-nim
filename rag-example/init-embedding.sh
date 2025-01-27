#!/bin/bash
set -x
echo "Running embedding init script"

export PATH=$PATH:/usr/bin
export DEBIAN_FRONTEND=noninteractive
export NGC_API_KEY=$(cat /root/ngc-api-key)

apt-get update
sleep 30
apt-get install -yq apt-transport-https ca-certificates curl gpg lsb-release unzip

curl -LO https://github.com/containerd/nerdctl/releases/download/v1.7.6/nerdctl-full-1.7.6-linux-amd64.tar.gz
tar Cxzvvf /usr/local nerdctl-full-1.7.6-linux-amd64.tar.gz
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/custom.conf
sysctl --system
systemctl start containerd
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update && apt-get install -yq nvidia-container-toolkit
nerdctl run --rm --gpus all ubuntu nvidia-smi

echo $NGC_API_KEY | docker login nvcr.io --username '$oauthtoken' --password-stdin
curl -LO https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/3.54.0/files/ngccli_linux.zip
unzip ngccli_linux.zip && chmod u+x ngc-cli/ngc && rm -rf ./ngccli_linux.zip
mkdir -p ~/.cache/nim
iptables -A CNI-FORWARD -p tcp -m tcp --dport 8000 -j ACCEPT

echo "COMMAND: nerdctl run -d --gpus='\"device=0\"'--shm-size=16GB --name embedding -e NGC_API_KEY -v ~/.cache/nim:/opt/nim/.cache -u 0 -p 8000:8000 nvcr.io/nim/nvidia/nv-embedqa-e5-v5:latest"