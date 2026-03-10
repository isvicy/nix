output "vm_name" {
  value = "win11"
}

output "disk_path" {
  value = "${var.pool_path}/win11.qcow2"
}

output "pool_path" {
  value = var.pool_path
}
