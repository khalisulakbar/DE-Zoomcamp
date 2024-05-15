variable "boot_disk_auto_delete" {
  type    = bool
  default = true
}

variable "boot_disk_device_name" {
  type    = string
  default = "de-project01-20240515-100122"
}

variable "boot_disk_image" {
  type    = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240508"
}

variable "boot_disk_size" {
  type    = number
  default = 20
}

variable "boot_disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "boot_disk_mode" {
  type    = string
  default = "READ_WRITE"
}

variable "can_ip_forward" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "enable_display" {
  type    = bool
  default = false
}

variable "labels" {
  type = map(string)
  default = {
    goog-ec-src = "vm_add-tf"
  }
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "name" {
  type    = string
  default = "de-project01-20240515-100122"
}

variable "network_tier" {
  type    = string
  default = "PREMIUM"
}

variable "queue_count" {
  type    = number
  default = 0
}

variable "stack_type" {
  type    = string
  default = "IPV4_ONLY"
}

variable "subnetwork" {
  type    = string
  default = "projects/data-engineering-423323/regions/us-central1/subnetworks/default"
}

variable "automatic_restart" {
  type    = bool
  default = true
}

variable "on_host_maintenance" {
  type    = string
  default = "MIGRATE"
}

variable "preemptible" {
  type    = bool
  default = false
}

variable "provisioning_model" {
  type    = string
  default = "STANDARD"
}

variable "service_account_email" {
  type    = string
  default = "33159520998xx0x-compute@developer.gserviceaccount.com"
}

variable "service_account_scopes" {
  type = list(string)
  default = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

variable "enable_integrity_monitoring" {
  type    = bool
  default = true
}

variable "enable_secure_boot" {
  type    = bool
  default = false
}

variable "enable_vtpm" {
  type    = bool
  default = true
}

variable "zone" {
  type    = string
  default = "us-central1-b"
}
