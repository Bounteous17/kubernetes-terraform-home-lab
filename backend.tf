terraform {
  cloud {
    organization = "Bounteous17"

    workspaces {
      name = "raspy-cluster"
    }
  }
}