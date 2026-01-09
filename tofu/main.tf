terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
      version = "1.0.2"
    }
  }
}

provider "incus" {}

resource "incus_profile" "static_ip_dhcp" {
  name = "static_ip_dhcp"
  
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

resource "incus_instance" "dhcp" {
  name = "dhcp"
  depends_on = [incus_profile.static_ip_dhcp]

  image = "images:alpine/3.23/cloud"
  profiles = [ "vxlan_1", "static_ip_dhcp"]
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
      users:
      - name: kacper
        ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9/twCahWHLkLGKrhbnXHGLXfh01jTVKsa84vaIIetj4rgtdQV40dJLxr7Og23EAdvgWBes0C0rboSRqeSikSKn3/BD0xIU1DpQoVuR9MjJDGpjYAuNrDDzOt/Y9ENNCaie0E0qWA0XBY0sKGsz1Nki0Th7V5tKXxvu2se7fP8rCTy3r6QsNZEB6HhJwovrFsFQUXxaxCKyd0eOtg8eQQiJ2wo95NxAX4kCiUae1IAkJ3y9I7UWNFhTbgYAB4qtFEjJlYuK0AeuBLEkYjUUOYEF0AYlO212b8iDA1jvhxiRaB99H/uZfCNBMmrCmdABHLHNzoPuL03MLgmxZXx4mu3/EDT7qnIj1GsyHMBQ4XHqq47vlrrf054lPPPKPfzQc5laakdpLPg6gp/yx4tHjGBW18heg9oM/hCs6CH9UjLHrua8SHSfq7w84QwLoRj1hTHJ3hiPbhCxj5boiVHj9jG1W07KRuD9a1keNSfTFg1jiqAB8VtOtuVrywtrOKqt6s= kacper@desktop
      manage_resolv_conf: true
      resolv_conf:
        nameservers:
          - '10.100.0.1'
        searchdomains:
          - lan
      packages:
      - dnsmasq
      - openssh-server
      
      write_files:
        - path: /etc/dnsmasq.d/dhcp.conf
          content: |
            interface=eth0
            dhcp-range=10.50.0.100,10.50.0.200,72h
            dhcp-option=3,10.50.0.1
            dhcp-option=6,10.100.0.1
      
      runcmd:
        - rc-update add dnsmasq default
        - rc-update add sshd default
        - rc-service dnsmasq start
        - rc-service sshd start
    EOT
  }
}

resource "incus_instance" "test-vm3" {
  name = "test-vm3"
  image = "images:debian/trixie/cloud"
  type = "virtual-machine"
  profiles = [ "vxlan_1"]
  config = {
    "boot.autostart" = true
    "security.secureboot" = false
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      users:
      - name: kacper
        ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9/twCahWHLkLGKrhbnXHGLXfh01jTVKsa84vaIIetj4rgtdQV40dJLxr7Og23EAdvgWBes0C0rboSRqeSikSKn3/BD0xIU1DpQoVuR9MjJDGpjYAuNrDDzOt/Y9ENNCaie0E0qWA0XBY0sKGsz1Nki0Th7V5tKXxvu2se7fP8rCTy3r6QsNZEB6HhJwovrFsFQUXxaxCKyd0eOtg8eQQiJ2wo95NxAX4kCiUae1IAkJ3y9I7UWNFhTbgYAB4qtFEjJlYuK0AeuBLEkYjUUOYEF0AYlO212b8iDA1jvhxiRaB99H/uZfCNBMmrCmdABHLHNzoPuL03MLgmxZXx4mu3/EDT7qnIj1GsyHMBQ4XHqq47vlrrf054lPPPKPfzQc5laakdpLPg6gp/yx4tHjGBW18heg9oM/hCs6CH9UjLHrua8SHSfq7w84QwLoRj1hTHJ3hiPbhCxj5boiVHj9jG1W07KRuD9a1keNSfTFg1jiqAB8VtOtuVrywtrOKqt6s= kacper@desktop
    EOT
  }
}
