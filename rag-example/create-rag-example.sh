#!/bin/bash
# run with 'source' to ensure that the envs are properly exported
if [ -z $DO_PAT ];then read -p "Enter Digital Ocean Personal Access Token: " do_pat;export DO_PAT=$do_pat;fi
if [ -z $NGC_API_KEY ];then read -p "Enter Nvidia NGC API Key: " ngc_api_key;export NGC_API_KEY=$ngc_api_key;fi
if [ -z $DO_SSH_KEYFILE ];then read -p "Enter path to private key for Digital Ocean droplets: " do_ssh_keyfile;export DO_SSH_KEYFILE=$do_ssh_keyfile;fi

DOMAIN="quyver.com"
export LLMHOSTNAME="llmhost"
export EMBEDDINGHOSTNAME="embeddinghost"

tofu init

tofu plan -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -var "gpuhost_names=[\"$LLMHOSTNAME\",\"$EMBEDDINGHOSTNAME\"]"

tofu apply -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -var "gpuhost_names=[\"$LLMHOSTNAME\",\"$EMBEDDINGHOSTNAME\"]" -auto-approve

tofu output -json |jq -r '.host_info.value | to_entries[]| "\(.value),\(.key)"' > outputs.txt

LLMHOSTIP=$(cat outputs.txt|grep $LLMHOSTNAME|cut -f 1 -d ",")
EMBEDDINGHOSTIP=$(cat outputs.txt|grep $EMBEDDINGHOSTNAME|cut -f 1 -d ",")

echo "Got LLM Host IP of $LLMHOSTIP"
echo "Got Embedding Host IP of $EMBEDDINGHOSTIP"

#remove old key fingerprints for dns names
ssh-keygen -f "/home/abe/.ssh/known_hosts" -R "$EMBEDDINGHOSTNAME.quyver.com"
ssh-keygen -f "/home/abe/.ssh/known_hosts" -R "$LLMHOSTNAME.quyver.com"

#copy the init scripte to each new host
scp -i $DO_SSH_KEYFILE ./init-llm.sh root@$LLMHOSTIP:~
scp -i $DO_SSH_KEYFILE init-embedding.sh root@$EMBEDDINGHOSTIP:~
#run the init scripts
ssh -i $DO_SSH_KEYFILE root@$LLMHOSTIP "chmod o+x ./init-llm.sh && ./init-llm.sh" &
ssh -i $DO_SSH_KEYFILE root@$EMBEDDINGHOSTIP "chmod o+x ./init-embedding.sh && ./init-embedding.sh" &
wait

#print out the LLM and Embedding endpoints for use in Python script
echo "Complete. Before accessing the inferencing endpoints, wait 5 minutes for the NIM containers to fully start up"
