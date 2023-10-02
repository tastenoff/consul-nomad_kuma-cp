addresses = {
http = "127.0.0.1 192.168.1.200"
}

advertise = {
  http = "192.168.1.200"
}

bind_addr = "192.168.1.200"

client {
  enabled = true
  node_class = "prod"
}

consul {
  address = "127.0.0.1:8500"
}

datacenter = "dc1"
data_dir  = "/var/lib/nomad"
disable_update_check = true

name = "Node1"

server {
  enabled = true
  bootstrap_expect = 3
}

ui {
  enabled =  true
  consul {
    ui_url = "http://localhost:8500/ui"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
    allow_privileged = true
    extra_labels = ["job_name", "task_group_name", "task_name", "namespace", "node_name"]

    allow_caps = [ "audit_write", "chown", "dac_override", "fowner", "fsetid", "kill", "mknod",
 "net_bind_service", "net_raw", "setfcap", "setgid", "setpcap", "setuid", "sys_chroot" ]

    gc {
      image = false
    }
  }
}