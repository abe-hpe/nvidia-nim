#!/bin/bash
# Export your Digital Ocean Personal Access Token as DO_PAT
# Export your Nvidia Developer API key as NV_API_KEY
# Export the location of the SSH key that allows access to your Digital Ocean droplets as DO_SSH_KEY_FILE
tofu init
tofu plan -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "nv_api=${NV_API_KEY}"
tofu apply -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "nv_api=${NV_API_KEY}" -auto-approve
tofu output > outputs.txt

# After the droplet is created, grab its IP address and add to /etc/hosts as nvidia-nim
HOST_IP=$(cat outputs.txt | grep host_ip_address | awk -F '"' '{print $2}')

#update entries in /etc/hosts
sudo sed -i '/nvidia-ni*/d' /etc/hosts
echo "$HOST_IP nvidia-nim" | sudo tee -a /etc/hosts



#ssh -i ~/.ssh/vtadmin.pem root@$HOST_IP "$KUBEJOIN" &


echo "Complete"
