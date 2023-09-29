###main.tf###
resource "libvirt_pool" "lab_pool" {
  name = "lab_pool"
  type = "dir"
  path = var.pool_dir
}

# Defining VM os-image Volume
resource "libvirt_volume" "base_image_volume" {
  name   = "base_image_volume"
  pool   = libvirt_pool.lab_pool.name
  source = var.base_image_location
  format = "qcow2"
}

# Defining VM data disk volume
resource "libvirt_volume" "vm_disk_volume" {
  for_each         = var.vms
  name             = "${each.key}_vm_disk_volume"
  base_volume_id   = libvirt_volume.base_image_volume.id
  base_volume_pool = libvirt_pool.lab_pool.name
  size             = each.value.libvirt_volume_size
}

# Defining cloud init config 
data "template_file" "cloud_init" {
  for_each = var.vms
  template = file("${path.module}/cloudinit/cloud_init.cfg")
}

# Defining VM cloudinit iso image creation 
resource "libvirt_cloudinit_disk" "cloudinit_disk" {
  for_each  = var.vms
  name      = "${each.key}_cloudinit_disk"
  pool      = libvirt_pool.lab_pool.name
  user_data = data.template_file.cloud_init[each.key].rendered
  # user_data_replace_on_change = true
}

# Define KVM domain creation
resource "libvirt_domain" "virtual_machine" {
  for_each   = var.vms
  name       = each.key
  memory     = each.value.memoryMB
  vcpu       = each.value.cpu
  qemu_agent = true

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm_disk_volume[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit_disk[each.key].id

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}
