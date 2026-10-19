variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/lab_ed25519.pub"
}

variable "admin_user" {
  type    = string
  default = "lab"
}

variable "base_image_path" {
  description = "Local path to the verified Ubuntu cloud image"
  type        = string
}

variable "pool_path" {
  type    = string
  default = "/var/lib/libvirt/lab"
}

variable "domain_name" {
  type    = string
  default = "lab.test"
}

variable "registry_enabled" {
  description = "Create the Harbor VM"
  type        = bool
  default     = false
}
