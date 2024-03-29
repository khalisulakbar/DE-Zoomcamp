terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
  credentials = file("./../keys/gcp_creds1.json")
  project     = "de-zoomcamp-411800"
  region      = "us-central1"
}

resource "google_storage_bucket" "demo-bucket" {
  name          = "de-zoomcamp-411800-terra-bucket"
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