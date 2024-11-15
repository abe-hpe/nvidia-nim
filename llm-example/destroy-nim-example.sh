#!/bin/bash
# Export your Digital Ocean Personal Access Token as DO_PAT
# Export your Nvidia Developer API key as NGC_API_KEY
# Export the location of the SSH key that allows access to your Digital Ocean droplets as DO_SSH_KEY_FILE
tofu destroy -var "do_token=${DO_PAT}" -var "pvt_key=${DO_SSH_KEYFILE}" -var "ngc_api_key=${NGC_API_KEY}" -auto-approve

echo "Destroyed"
