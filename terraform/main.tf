locals {
  subnet  = "192.168.150"
  gateway = "${local.subnet}.1"

  core_nodes = {
    cp1 = { role = "control_plane", ip = "${local.subnet}.10", mac = "52:54:00:15:00:10", vcpu = 2, memory_mib = 4096, disk_gib = 40 }
    w1  = { role = "worker", ip = "${local.subnet}.11", mac = "52:54:00:15:00:11", vcpu = 2, memory_mib = 6144, disk_gib = 40 }
    w2  = { role = "worker", ip = "${local.subnet}.12", mac = "52:54:00:15:00:12", vcpu = 2, memory_mib = 6144, disk_gib = 40 }
  }

  registry_node = {
    registry = { role = "registry", ip = "${local.subnet}.20", mac = "52:54:00:15:00:20", vcpu = 2, memory_mib = 4096, disk_gib = 80 }
  }

  vms = merge(local.core_nodes, var.registry_enabled ? local.registry_node : {})
}

# ---------- storage pool ----------
resource "libvirt_pool" "lab" {
  name = "lab"
  type = "dir"
  target = {
    path = var.pool_path
  }
  create = {
    build     = true
    start     = true
    autostart = true
  }
  destroy = {
    delete = false
  }
}

# ---------- network (NAT, static addressing done by cloud-init) ----------
# VERIFY-2: forward / bridge / domain / ips / create
resource "libvirt_network" "lab" {
  name = "lab"
  forward = {
    mode = "nat"
  }
  bridge = {
    name = "virbr-lab"
  }
  domain = {
    name = var.domain_name
  }
  ips = [{
    address = local.gateway
    netmask = "255.255.255.0"
  }]
  autostart = true
}

# ---------- base image (uploaded once) and per-VM copy-on-write disks ----------
# VERIFY-1: target.format.type, backing_store, capacity, capacity_unit
resource "libvirt_volume" "base" {
  name = "ubuntu-24.04-base.qcow2"
  pool = libvirt_pool.lab.name
  target = {
    format = { type = "qcow2" }
  }
  create = {
    content = {
      url = pathexpand(var.base_image_path)
    }
  }
}

resource "libvirt_volume" "root" {
  for_each      = local.vms
  name          = "${each.key}-root.qcow2"
  pool          = libvirt_pool.lab.name
  capacity      = each.value.disk_gib
  capacity_unit = "GiB"
  target = {
    format = { type = "qcow2" }
  }
  backing_store = {
    path   = libvirt_volume.base.path
    format = { type = "qcow2" }
  }
}

# ---------- cloud-init ----------
# VERIFY-3: network_config attribute
resource "libvirt_cloudinit_disk" "init" {
  for_each = local.vms
  name     = "${each.key}-init"

  user_data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    hostname       = each.key
    fqdn           = "${each.key}.${var.domain_name}"
    admin_user     = var.admin_user
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })

  meta_data = yamlencode({
    instance-id    = "${each.key}-v1"
    local-hostname = each.key
  })

  network_config = templatefile("${path.module}/templates/network-config.yaml.tftpl", {
    mac     = each.value.mac
    ip      = each.value.ip
    gateway = local.gateway
  })
}

resource "libvirt_volume" "init" {
  for_each = local.vms
  name     = "${each.key}-init.iso"
  pool     = libvirt_pool.lab.name
  target = {
    format = { type = "iso" }
  }
  create = {
    content = {
      url = libvirt_cloudinit_disk.init[each.key].path
    }
  }
}

# ---------- the VMs ----------
# VERIFY-4: cpu, running, disks[*].driver, interfaces[*].mac
resource "libvirt_domain" "node" {
  for_each    = local.vms
  name        = "lab-${each.key}"
  type        = "kvm"
  memory      = each.value.memory_mib
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  running     = true

  features = {
  acpi = true
  apic = {}
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    serials  = [{ target = { port = 0 } }]
    consoles = [{ target = { type = "serial", port = 0 } }]
    disks = [
      {
        device = "disk"
        driver = { name = "qemu", type = "qcow2" }
        target = { dev = "vda", bus = "virtio" }
        source = {
          volume = {
            pool   = libvirt_pool.lab.name
            volume = libvirt_volume.root[each.key].name
          }
        }
      },
      {
        device = "cdrom"
        target = { dev = "sda", bus = "sata" }
        source = {
          volume = {
            pool   = libvirt_pool.lab.name
            volume = libvirt_volume.init[each.key].name
          }
        }
      }
    ]
    interfaces = [
      {
        mac    = { address = each.value.mac }
        model  = { type = "virtio" }
        source = { network = { network = libvirt_network.lab.name } }
      }
    ]
  }
}
