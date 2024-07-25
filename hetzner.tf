# Tell terraform to use the provider and select a version.
terraform {
    required_providers {
        hcloud = {
            source = "hetznercloud/hcloud"
            version = "~> 1.45"
        }
    }
}

# using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
    type = string
    sensitive = true
}

# SSH Public Key -> needs to be replaced with every new deployment
data "hcloud_ssh_key" "ansible-ssh-key" {
  name = "Ansible"
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
    token = var.hcloud_token
}

# Create a network
resource "hcloud_network" "Ansible-Network" {
    name = "Ansible-Network"
    ip_range = "10.0.0.0/8"
}

# Create a sub-network
resource "hcloud_network_subnet" "Ansible-Sub-Network" {
    type = "cloud"
    network_id = hcloud_network.Ansible-Network.id
    ip_range = "10.10.0.0/24"
    network_zone = "eu-central"

}


# Create Ansible Controller
resource "hcloud_server" "Ansible-Controller" {
    name        = "Ansible-Controller"
    image       = "debian-12"
    # Currently: 2 vCPUs (shared), 4 GB RAM, 40 GB Disk, 20 TB Traffic, 0.006 €/h -> 3,92 €/month
    server_type = "cx22"
    location    = "fsn1"
    user_data = file("ansible-config.yml")

    labels = {
        "env" = "test"
        "role" = "ansible-controller"
    }

    ssh_keys = [
        data.hcloud_ssh_key.ansible-ssh-key.id
    ]

    keep_disk = true
    public_net {
        # no ipv4 address -> 1 €/month extra
        ipv4_enabled = false
        # ipv6 address for external internet access -> free
        ipv6_enabled = true
    }

    network {
        network_id = hcloud_network.Ansible-Network.id
        ip = "10.10.0.10"
    }

    depends_on = [
        hcloud_network_subnet.Ansible-Sub-Network
    ]
}

# Create Ansible Nodes (1-3)
resource "hcloud_server" "Ansible-Node" {
    count       = 3
    name        = "Ansible-Node-${count.index}"
    image       = "debian-12"
    # Currently: 2 vCPUs (shared), 4 GB RAM, 40 GB Disk, 20 TB Traffic, 0.006 €/h -> 3,92 €/month
    server_type = "cx22"
    location    = "fsn1"

    labels = {
        "env" = "test"
        "role" = "ansible-node"
    }

    ssh_keys = [
        data.hcloud_ssh_key.ansible-ssh-key.id
    ]

    keep_disk = true
    public_net {
        # no ipv4 address -> 1 €/month extra
        ipv4_enabled = false
        # ipv6 address for external internet access -> free
        ipv6_enabled = true
    }

    network {
        network_id = hcloud_network.Ansible-Network.id
        ip = "10.10.0.${count.index + 11}"
    }

    depends_on = [
        hcloud_network_subnet.Ansible-Sub-Network
    ]
}

# Create Ansible Inventory File
resource "local_file" "ansible_inventory" {
  content = yamlencode({
    all = {
      children = {
        controller = {
          hosts = {
            (hcloud_server.Ansible-Controller.name) = {
              ansible_host = hcloud_server.Ansible-Controller.ipv6_address
              ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
            }
          }
        }
        nodes = {
          hosts = {
            for node in hcloud_server.Ansible-Node : node.name => {
              ansible_host = node.network.*.ip[0]
              ansible_ssh_common_args = "-o StrictHostKeyChecking=no"
            }
          }
        }
      }
      vars = {
        ansible_user                 = "root"
        ansible_ssh_private_key_file = "~/.ssh/id_rsa"
        ansible_python_interpreter   = "/usr/bin/python3"
      }
    }
  })
  filename = "${path.module}/inventory.yml"
}

output "ansible_controller_ipv6" {
  value = hcloud_server.Ansible-Controller.ipv6_address
  description = "The IPv6 address of the Ansible Controller"
}

output "next_steps" {
  value = <<EOT

Next steps:
1. Copy the inventory.yml file to the Ansible Controller:
   scp -6 ${path.module}/inventory.yml root@[${hcloud_server.Ansible-Controller.ipv6_address}]:/root/inventory.yml

2. Copy your SSH private key to the Ansible Controller:
   scp -6 ~/.ssh/id_rsa root@[${hcloud_server.Ansible-Controller.ipv6_address}]:/root/.ssh/id_rsa

3. SSH into the Ansible Controller:
   ssh -6 root@${hcloud_server.Ansible-Controller.ipv6_address}

4. Once on the Ansible Controller, run the following command to verify connectivity:
   ansible all -i /root/inventory.yml -m ping

Remember to ensure your local machine has IPv6 connectivity.
EOT
  description = "Instructions for next steps after Terraform apply"
}
