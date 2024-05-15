terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
  credentials = file("./../keys/gcp_creds2.json")
  project     = "data-engineering-423323"
  region      = "us-central1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "de-project-4712-bucket"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}