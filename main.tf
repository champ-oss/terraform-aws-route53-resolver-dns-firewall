locals {
  tags = {
    git       = var.git
    cost      = "shared"
    creator   = "terraform"
    component = "resolver-dns-firewall"
  }
}