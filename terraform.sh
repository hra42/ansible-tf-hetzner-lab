#bin/bash
# Author: Henry Rausch
# Version: 1.0
# GitHub: https://github.com/hra42
# Date: 25.07.2024
# Description: This script is used to make the use of the terraform docker image easier
# It will run the docker image with the current directory mounted as /terraform

# Pull the latest terraform image
docker pull hashicorp/terraform:latest

# Allow the user to override the default script with init, plan, apply, or destroy
if [ "$1" == "init" ]; then
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest init
elif [ "$1" == "plan" ]; then
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest plan
elif [ "$1" == "apply" ]; then
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest apply
elif [ "$1" == "destroy" ]; then
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest destroy
else
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest init && \
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest plan -out=tfplan && \
    docker run --rm -v ${PWD}:/terraform -w /terraform hashicorp/terraform:latest apply tfplan -auto-approve
fi

# Clean up the tfplan file
rm -f tfplan

# Exit with the exit code of the last command
exit $?
