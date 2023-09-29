output "ssh_connections" {
  description = "IPv4 addresses of the created VMs"
  value = {
    for name, vm in libvirt_domain.virtual_machine : name => "SSH command: ssh -i ~/.ssh/virt deployer@${vm.network_interface[0].addresses[0]}"
  }
}