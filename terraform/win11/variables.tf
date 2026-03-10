variable "win11_iso_path" {
  type    = string
  default = "/data/iso/win11.iso"
}

variable "virtio_iso_path" {
  type    = string
  default = "/data/iso/virtio-win.iso"
}

variable "vcpus" {
  type    = number
  default = 28
}

variable "memory_mb" {
  type    = number
  default = 49152 # 48 GB
}

variable "disk_size_bytes" {
  type        = number
  default     = 2199023255552 # 2 TB
  description = "Disk size in bytes"
}

variable "pool_path" {
  type    = string
  default = "/data/libvirt/win11"
}

variable "ovmf_code_path" {
  type    = string
  default = "/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd"
}

variable "nvram_path" {
  type    = string
  default = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd"
}
