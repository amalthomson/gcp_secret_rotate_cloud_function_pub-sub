terraform {
  backend "gcs" {
    bucket = "terraform-remote-backend-implementation"
    prefix = "secret-rotation-with-gcf/terraform/state"
  }
}