# Virtual setup machines variable
variable "vms" {
  description = "map of vm names to configuration."
  type = map(object({
    memoryMB            = string,
    cpu                 = string,
    libvirt_volume_size = string
  }))
}

variable "base_image_location" {
  type        = string
  description = "a path for boot disk"
}

variable "pool_dir" {
  type        = string
  description = "a directory to use as an pool storage"
}