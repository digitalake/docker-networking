resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/tftpls/inventory.tftpl",
    { content = {
      for k, v in libvirt_domain.virtual_machine : k => v.network_interface.0.addresses.0 }
    }
  )
  filename = "${path.module}/ansible/inventory"
}
