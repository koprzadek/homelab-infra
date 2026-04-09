terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
      version = "1.0.2"
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
resource "incus_storage_volume" "nextcloud_data" {
  name = "nextcloud-data"
  pool = "local"
  type = "custom"
  target = "nix-c1"
}

resource "incus_instance" "nix-k" {
  name = "nix-k${count.index}"
  count = 3
  image = "nixos/vm"
  type = "virtual-machine"
  profiles = [ "vxlan_1"]
  config = {
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: nix-k${count.index}
    EOF
  }
}

resource "incus_instance" "nix-p" {
  depends_on = [incus_storage_volume.nextcloud-data]
  count = 1
  name = "nix-p${count.index}"
  image = "nixos/container"
  profiles = [ "vxlan_2"]
  config = {
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: nix-p${count.index}
    EOF
  }

  device {
    name = "nextcloud-data"
    type = "disk"
    properties = {
      pool   = incus_storage_volume.nextcloud_data.pool
      source = incus_storage_volume.nextcloud_data.name
      path   = "/var/lib/nextcloud/data" # verify for your image
    }
  }

  target = incus_storage_volume.nextcloud_data.location
}

resource "incus_storage_volume" "nextcloud-data" {
  name = "nextcloud-data"
  pool = incus_storage_pool.p1.name

}

