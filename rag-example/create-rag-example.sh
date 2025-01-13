#!/bin/bash
# run with 'source' to ensure that the envs are properly exported
if [-z $DO_PAT]; then read -p "Enter Digital Ocean Personal Access Token: " do_pat;export DO_PAT=$do_pat;fi
if [-z $NGC_API_KEY]; then read -p "Enter Nvidia NGC API Key: " ngc_api_key;export NGC_API_KEY=$ngc_api_key;fi
if [-z $DO_SSH_KEYFILE]; then read -p "Enter path to private key for Digital Ocean droplets: " do_ssh_keyfile;export DO_SSH_KEYFILE=$do_ssh_keyfile;fi

tofu init
tofu plan -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}"
tofu apply -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -auto-approve
tofu output |tee outputs.txt

# After the droplet is created, grab its IP address and add to /etc/hosts as nvidia-nim
#llm_host_ip=$(cat outputs.txt | grep host_ip_address | awk -F '"' '{print $2}')

#update entries in /etc/hosts
#sudo sed -i '/nvidia-ni*/d' /etc/hosts
#echo "$host_ip nvidia-nim" | sudo tee -a /etc/hosts

echo "Complete. Before accessing the inferencing endpoint, wait 5 minutes for the NIM container to fully start up"
