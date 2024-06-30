terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.23.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.47.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "coder" {
}

variable "hcloud_token" {
  description = <<EOF
Coder requires a Hetzner Cloud token to provision workspaces.
EOF
  sensitive   = true
  validation {
    condition     = length(var.hcloud_token) == 64
    error_message = "Please provide a valid Hetzner Cloud API token."
  }
}

variable "instance_location" {
  description = "What region should your workspace live in?"
  default     = "fsn1"
  validation {
    condition     = contains(["nbg1", "fsn1", "hel1"], var.instance_location)
    error_message = "Invalid zone!"
  }
}

variable "instance_type" {
  description = "What instance type should your workspace use?"
  default     = "cpx11"
  validation {
    condition     = contains(["cx22", "cpx11", "cx32", "cpx21", "cpx31", "cx42", "cx41", "cpx51"], var.instance_type)
    error_message = "Invalid instance type!"
  }
}

variable "instance_os" {
  description = "Which operating system should your workspace use?"
  default     = "ubuntu-24.04"
  validation {
    condition     = contains([
      "ubuntu-24.04", 
      "fedora-40", 
      "debian-12", 
      "centos-stream-9", 
      "almalinux-9", 
      "rockylinux-9"
    ], var.instance_os)
    error_message = "Invalid OS!"
  }
}

variable "volume_size" {
  description = "How much storage space do you need in GB (can't be less then 10)?"
  default     = "10"
  validation {
    condition     = var.volume_size >= 10
    error_message = "Invalid volume size!"
  }
}

variable "code_server" {
  description = "Should Code Server be installed?"
  default     = "true"
  validation {
    condition     = contains(["true","false"], var.code_server)
    error_message = "Your answer can only be yes or no!"
  }
}

data "coder_workspace" "me" {}

resource "coder_agent" "dev" {
  arch = "amd64"
  os   = "linux"

   metadata {
    display_name = "CPU Usage"
    key          = "cpu_usage"
    order        = 0
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "ram_usage"
    order        = 1
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk Usage (Host)"
    key          = "disk_host"
    order        = 6
    script       = "coder stat disk --path /"
    interval     = 600
    timeout      = 10
  }  
}  


resource "coder_app" "code-server" {
  agent_id     = coder_agent.dev.id
  slug         = "code-server"
  display_name = "VS Code"
  icon         = "${data.coder_workspace.me.access_url}/icon/code.svg"
  url          = "http://localhost:8080"
  share        = "owner"
  subdomain    = false
  healthcheck {
    url       = "http://localhost:8080/healtz"
    interval  = 5
    threshold = 6
  }
}

# Generate a dummy ssh key that is not accessible so Hetzner cloud does not spam the admin with emails.
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "root" {
  name       = "coder-${data.coder_workspace.me.name}-root"
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "hcloud_server" "root" {
  count       = data.coder_workspace.me.start_count
  name        = "coder-${data.coder_workspace.me.name}-root"
  server_type = var.instance_type
  location    = var.instance_location
  image       = var.instance_os
  ssh_keys    = [hcloud_ssh_key.root.id]
  user_data   = templatefile("cloud-config.yaml.tftpl", {
    username          = data.coder_workspace.me.name
    volume_path       = "/dev/disk/by-id/scsi-0HC_Volume_${hcloud_volume.root.id}"
    init_script       = base64encode(coder_agent.dev.init_script)
    coder_agent_token = coder_agent.dev.token
    code_server_setup = var.code_server
  })
}

resource "hcloud_volume" "root" {
  name         = "coder-${data.coder_workspace.me.name}-root"
  size         = var.volume_size
  format       = "ext4"
  location     = var.instance_location
}

resource "hcloud_volume_attachment" "root" {
  count     = data.coder_workspace.me.start_count
  volume_id = hcloud_volume.root.id
  server_id = hcloud_server.root[count.index].id
  automount = false
}

resource "hcloud_firewall" "root" {
  name = "coder-${data.coder_workspace.me.name}-root"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "root_fw_attach" {
    count = data.coder_workspace.me.start_count
    firewall_id = hcloud_firewall.root.id
    server_ids  = [hcloud_server.root[count.index].id]
}
