data_dir = "/var/lib/nomad"

server {
  enabled          = true
  bootstrap_expect = 3
}

client {
  enabled = true
}

consul {
  address = "192.168.1.200:8500"
}

etcd {
  address = "http://192.168.1.200:2379"
}
