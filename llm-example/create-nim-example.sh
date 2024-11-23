#!/bin/bash
# run with 'source' to ensure that the envs are properly exported
read -p "Enter Digital Ocean Personal Access Token: " do_pat
read -p "Enter Nvidia NGC API Key: " ngc_api_key
read -p "Enter path to private key for Digital Ocean droplets: " do_ssh_keyfile

PS3="Select a NIM to deploy:"

nimnames=$(cat nim-info.csv|awk -F',' '{print $1}')
nimimages=($(cat nim-info.csv|awk -F',' '{print $2}'))

select nim in $nimnames; do
  [ -n "${nim}" ] && break
done

export DO_PAT=$do_pat
export DO_SSH_KEYFILE=$do_ssh_keyfile
export NGC_API_KEY=$ngc_api_key
export NIM_IMAGE=${nimimages[$REPLY-1]}


tofu init
tofu plan -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -var "nim_image=${NIM_IMAGE}"
tofu apply -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -var "nim_image=${NIM_IMAGE}" -auto-approve
tofu output |tee outputs.txt

# After the droplet is created, grab its IP address and add to /etc/hosts as nvidia-nim
host_ip=$(cat outputs.txt | grep host_ip_address | awk -F '"' '{print $2}')

#update entries in /etc/hosts
sudo sed -i '/nvidia-ni*/d' /etc/hosts
echo "$host_ip nvidia-nim" | sudo tee -a /etc/hosts

echo "Complete. Before accessing the inferencing endpoint, wait 5 minutes for the NIM container to fully start up"
