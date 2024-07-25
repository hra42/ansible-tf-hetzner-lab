# Terraform Hetzner Cloud Ansible Setup

This project uses Terraform to set up an Ansible environment on Hetzner Cloud. It creates an Ansible controller and multiple Ansible nodes, all connected via a private network.

## Files

1. `terraform.sh`: A bash script to simplify running Terraform commands using Docker.
2. `hetzner.tf`: The main Terraform configuration file for creating resources on Hetzner Cloud.
3. `ansible-config.yml`: A cloud-init configuration file for setting up the Ansible controller.

## Prerequisites

- Docker installed on your local machine
- A Hetzner Cloud account and API token (security>api-tokens>add API token)
- SSH key pair (the public key should be uploaded to your Hetzner Cloud account with the name "Ansible")

## Usage

1. Clone this repository to your local machine.

2. Set your Hetzner Cloud API token as an environment variable:
   ```bash
   export TF_VAR_hcloud_token=your_hetzner_cloud_api_token
   ```

3. Run the Terraform script:
   ```bash
   ./terraform.sh
   ```
   This will initialize Terraform, create a plan, and apply the changes.

4. After the script completes, follow the instructions in the "Next steps" output to:
   - Copy the inventory file to the Ansible controller
   - Copy your SSH private key to the Ansible controller
   - SSH into the Ansible controller
   - Verify connectivity with all nodes

## Infrastructure Details

- 1 Ansible Controller (Debian 12, cx22 server type)
- 3 Ansible Nodes (Debian 12, cx22 server type)
- Private network (10.0.0.0/8) with a subnet (10.10.0.0/24)
- IPv6 enabled for all servers (no public IPv4 addresses to save costs)

## Customization

- Modify the `hetzner.tf` file to change the number of nodes, server types, or other configurations.
- Adjust the `ansible-config.yml` file to customize the initial setup of the Ansible controller.

## Clean Up

To destroy all created resources, run:
```bash
./terraform.sh destroy
```

## Note

Ensure your local machine has IPv6 connectivity to access the created servers.
