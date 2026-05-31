resource "incus_storage_pool" "d1_n1" {
  name   = "volumes"
  driver = "dir"
  target = "nix-nas"
}

resource "incus_storage_pool" "d1_n2" {
  name   = "volumes"
  driver = "dir"
  target = "nix-c1"
}

resource "incus_storage_pool" "volumes" {
  depends_on = [
    incus_storage_pool.d1_n1,
    incus_storage_pool.d1_n2,
  ]

  name   = "volumes"
  driver = "dir"
}
