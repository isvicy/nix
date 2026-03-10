terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Storage pool on /data
resource "libvirt_pool" "win11" {
  name = "win11"
  type = "dir"

  target = {
    path = var.pool_path
  }
}

# 2 TB qcow2 disk
resource "libvirt_volume" "win11" {
  name     = "win11.qcow2"
  pool     = libvirt_pool.win11.name
  capacity = var.disk_size_bytes

  target = {
    format = { type = "qcow2" }
  }
}

# Render domain XML from template
locals {
  domain_xml = templatefile("${path.module}/templates/win11.xml.tftpl", {
    name         = "win11"
    memory_mb    = var.memory_mb
    vcpus        = var.vcpus
    disk_path    = "${var.pool_path}/win11.qcow2"
    win11_iso    = var.win11_iso_path
    virtio_iso   = var.virtio_iso_path
    ovmf_code    = var.ovmf_code_path
    nvram_path   = var.nvram_path
    network_name = "default"
  })
}

# Define VM via virsh (provider lacks TPM/hostdev/topology support)
resource "terraform_data" "win11_domain" {
  depends_on = [libvirt_volume.win11]

  input = local.domain_xml

  provisioner "local-exec" {
    command = <<-EOT
      cat > /tmp/win11-domain.xml <<'XMLEOF'
${local.domain_xml}
XMLEOF
      virsh -c qemu:///system define /tmp/win11-domain.xml && rm -f /tmp/win11-domain.xml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "virsh -c qemu:///system destroy win11 2>/dev/null; virsh -c qemu:///system undefine win11 --nvram 2>/dev/null; true"
  }
}
