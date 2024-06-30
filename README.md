# coder-hetzner-cloud-template

This repository provides a Terraform template for Coder (https://github.com/coder/coder) that facilitates the setup of a cloud-based development environment using Hetzner Cloud. It allows provisioning of instances with optional vscode installation.

## Usage

- Download files from repo
- Add them to .tar archive / or use the included one
- Create template in Coder by Uploading the .tar file
- Add hcloud API token from (https://console.hetzner.cloud/projects/<YOUR_PROJECT_ID>/security/tokens)

## Features

![Hetzner Cloud Logo](https://cdn.hetzner.com/assets/Uploads/Hetzner-Logo-slogan_space-trans.png)

- Creates a Hetzner Cloud instance.
- Creates a Hetzner Cloud volume.
- Sets up a default inbound firewall policy.
- Attaches volumes and firewall policies to the instance.
- Offers the option to install code-server based on user preference.

## Updated Terraform Versions

- coder/coder: 0.23.0
- hetznercloud/hcloud: 1.47.0

## Changes

- added metadata blocks for stats
- included .tar file for template upload

## Default Variables

- `instance_location`: fsn1/Falkenstein (eu-central)
- `instance_type`: cpx11
  - Hetzner Cloud server with shared AMD vCPU
  - **Specifications:**
    - **Name:** CPX11
    - **vCPUs:** 2
    - **RAM:** 2 GB
    - **SSD:** 40 GB
    - **Traffic:** 20 TB
    - **Price:** €0.008/h, €4.66/mo, €0.61/IPv4
- `instance_os`: ubuntu-24.04
- `volume_size`: 10 GB (minimum) persistent volume

## Credits

- [ntimo/coder-hetzner-cloud-template](https://github.com/ntimo/coder-hetzner-cloud-template)
- [coder/terraform-provider-coder](https://github.com/coder/terraform-provider-coder)
- [hetznercloud/terraform-provider-hcloud](https://github.com/hetznercloud/terraform-provider-hcloud)
