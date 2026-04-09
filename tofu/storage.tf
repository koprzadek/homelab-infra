resource "incus_storage_pool" "p1_nas" {
  name   = "p1"
  driver = "dir"
  target = "nix-nas"
}

resource "incus_storage_pool" "p1_c1" {
  name   = "p1"
  driver = "dir"
  target = "nix-c1"
}

resource "incus_storage_pool" "p1" {
  depends_on = [
    incus_storage_pool.p1_nas,
    incus_storage_pool.p1_c1,
  ]

  name   = "p1"
  driver = "dir"
}
