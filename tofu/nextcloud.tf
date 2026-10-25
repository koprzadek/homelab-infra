resource "incus_storage_volume" "nextcloud" {
  name = "nextcloud"
  pool = incus_storage_pool.volumes.name
  target = "nix-c1"
}

resource "incus_storage_volume" "postgresql" {
  name = "postegresql"
  pool = incus_storage_pool.volumes.name
  target = "nix-c1"
}


resource "incus_instance" "nix-n" {
  count = 1
  name = "nix-n${count.index}"
  image = "nixos/container"
  profiles = [ "vxlan_2"]
  config = {
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: nix-p${count.index}
    EOF
  }

  device {
    name = "nextcloud"
    type = "disk"
    properties = {
      path = "/data/nextcloud"
      source = incus_storage_volume.nextcloud.name
      pool = incus_storage_pool.volumes.name
    }
  }

  device {
    name = "postgresql"
    type = "disk"
    properties = {
      path = "/var/lib/postgresql"
      source = incus_storage_volume.postgresql.name
      pool = incus_storage_pool.volumes.name
    }
  }


  target = incus_storage_volume.nextcloud.target
}
