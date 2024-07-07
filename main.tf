variable "photoprism_admin" {}
variable "photoprism_db_connection_string" {}

module "photoprism" {
  source = "./applications/photoprism"
  photoprism_admin = var.photoprism_admin
  photoprism_db_connection_string = var.photoprism_db_connection_string
}