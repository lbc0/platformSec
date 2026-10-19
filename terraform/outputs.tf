output "ansible_inventory" {
  description = "Ansible YAML/JSON inventory generated from the VM definitions"
  value = {
    all = {
      vars = {
        ansible_user = var.admin_user
      }
      children = {
        control_plane = {
          hosts = { for k, v in local.vms : k => { ansible_host = v.ip } if v.role == "control_plane" }
        }
        workers = {
          hosts = { for k, v in local.vms : k => { ansible_host = v.ip } if v.role == "worker" }
        }
        registry = {
          hosts = { for k, v in local.vms : k => { ansible_host = v.ip } if v.role == "registry" }
        }
      }
    }
  }
}
