locals {
  targets = [
    "nix-nas",
    "nix-c1",
    "nix-nas",
  ]
}

resource "incus_instance" "nix-ks" {
  count = 0
  type = "virtual-machine"
  name = "nix-ks${count.index}"
  image = "nixos/vm"
  profiles = [ "vxlan_1"]
  config = {
    "limits.cpu"     = 2
    "limits.memory"  = "2GiB"
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: nix-ks${count.index}
    EOF
  }
  target = local.targets[count.index]
}

resource "incus_instance" "nix-k2" {
  count = 2
  type = "virtual-machine"
  name = "nix-kw${count.index}"
  image = "nixos/vm"
  profiles = [ "vxlan_1"]
  config = {
    "limits.cpu"     = 2
    "limits.memory"  = "6GiB"
    "user.user-data" = <<-EOF
      #cloud-config
      hostname: nix-kw${count.index}
    EOF
  }
  target = local.targets[count.index]
}
