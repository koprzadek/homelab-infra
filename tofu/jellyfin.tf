resource "incus_storage_volume" "jellyfin_data" {
  name = "jellyfin_data"
  pool = incus_storage_pool.volumes.name
}

resource "incus_instance" "nix-p" {
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
    name = "jellyfin_data"
    type = "disk"
    properties = {
      path = "/var/lib/jellyfin"
      source = incus_storage_volume.jellyfin_data.name
      pool = incus_storage_pool.volumes.name
    }
  }

  device {
    name = "gpu"
    type = "gpu"
    properties = {
      gid = "303"
      mode = "666"
    }
  }

  device {
    name = "media"
    type = "disk"
    properties = {
      path = "/data/media"
      source = "/ssd/media"
    }
  }

  target = incus_storage_volume.jellyfin_data.target
}
