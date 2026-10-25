terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
      version = "1.0.2"
    }
  }

  backend "s3" {
    bucket = "homelab-tofu-backend"
    key = "terraform.tfstate"
    region = "auto"

    use_lockfile = false
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true

    endpoints = {
      s3 = "https://18d4f014fdfeae80a01bdf486ef52ef4.r2.cloudflarestorage.com"
    }
  }
}

provider "incus" {}

resource "incus_profile" "static_ip_dhcp_50_0" {
  name = "static_ip_dhcp_50_0"
  config = {
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          match:
            name: eth0
          addresses:
           - 10.50.0.3/24
          routes: 
           - to: default
             via: 10.50.0.1
    EOT
  }
}

resource "incus_profile" "static_ip_dhcp_60_0" {
  name = "static_ip_dhcp_60_0"
  config = {
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          match:
            name: eth0
          addresses:
           - 10.60.0.3/24
          routes: 
           - to: default
             via: 10.60.0.1
    EOT
  }
}


resource "incus_instance" "dhcp-50-0" {
  name = "dhcp-50-0"
  depends_on = [incus_profile.static_ip_dhcp_50_0]

  image = "images:alpine/3.23/cloud"
  profiles = [ "vxlan_1", "static_ip_dhcp_50_0"]
  config = {
    "boot.autostart" = true
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          match:
            name: eth0
          addresses:
           - 10.50.0.3/24
          routes: 
           - to: default
             via: 10.50.0.1
    EOT
    
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      manage_resolv_conf: true
      resolv_conf:
        nameservers:
          - '10.100.0.1'
        searchdomains:
          - lan
      packages:
      - dhcp-helper
      - dhcp-helper-openrc
      
      write_files:
        - path: /etc/conf.d/dhcp-helper
          content: |
            ARGS="-s 10.100.0.1"
      
      runcmd:
        - rc-update add dhcp-helper default
        - rc-service dhcp-helper start
    EOT
  }
}

resource "incus_instance" "dhcp-60-0" {
  name = "dhcp-60-0"
  depends_on = [incus_profile.static_ip_dhcp_60_0]

  image = "images:alpine/3.23/cloud"
  profiles = [ "vxlan_2", "static_ip_dhcp_60_0"]
  config = {
    "boot.autostart" = true
    "cloud-init.network-config" = <<-EOT
      version: 2
      ethernets:
        eth0:
          match:
            name: eth0
          addresses:
           - 10.60.0.3/24
          routes: 
           - to: default
             via: 10.60.0.1
    EOT
    
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      manage_resolv_conf: true
      resolv_conf:
        nameservers:
          - '10.100.0.1'
        searchdomains:
          - lan
      packages:
      - dhcp-helper
      - dhcp-helper-openrc
      
      write_files:
        - path: /etc/conf.d/dhcp-helper
          content: |
            ARGS="-s 10.100.0.1"
      
      runcmd:
        - rc-update add dhcp-helper default
        - rc-service dhcp-helper start
    EOT
  }
}
