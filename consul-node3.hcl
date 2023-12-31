bind_addr = "192.168.64.7"
datacenter = "dc1"
node_name = "Node3"
data_dir = "/tmp/consul"
server = true
bootstrap_expect = 3
rejoin_after_leave = true

retry_join = [
  "192.168.64.5",
  "192.168.64.6"
]

addresses = {
  http = "127.0.0.1 192.168.64.7"
  grpc = "127.0.0.1 192.168.64.7"
}

ui_config = {
  enabled = true
}

ports = {
  dns = 53
  grpc = 8502
}

recursors = [
  "1.1.1.1",
  "1.0.0.1",
  "8.8.8.8",
  "8.8.4.4",
  "2606:4700:4700::1111",
  "2001:4860:4860::8888"
]

dns_config = {
  node_ttl = "1m"
  recursor_timeout = "1.5s"
}
