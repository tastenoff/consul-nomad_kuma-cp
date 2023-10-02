job "test-job-2" {
  datacenters = ["dc1"]
  type        = "service"

  group "test-group" {


    network {
      mode = "bridge"
      port "app_port2" {
        static = 9090
      }
      port "api_server" {
      	static = 5681
      }
      port "dp_server" {
      	static = 5678
      }
      }

    task "test-task-2" {
      driver = "docker"

      config {
        image = "alpine:latest"
        command = "sh"
        args = [ "-c", "echo 'Hello, Abay!'; sleep infinity" ]
        ports = ["app_port2"]
      }


      service {
        name = "test-app"
        port = "dp_server"
      }
    }
    
    
    task "sidecar" {
        driver = "docker"

        lifecycle {
            hook = "prestart"
            sidecar = true
        }

        config {
            image = "kumahq/kuma-dp:2.4.1"
          	extra_hosts = ["kuma-cp.service.consul:192.168.64.6"]
            entrypoint = [ "sh" ]
            args  = [ "$${NOMAD_TASK_DIR}/entrypoint.sh" ]
          	ports = ["dp_server","api_server"]
        }

        template {
            data = <<-EOF
            #!/bin/sh
            
            kuma-dp run \
            						--cp-address https://kuma-cp.service.consul:5678 \
            						--dataplane-file $${NOMAD_TASK_DIR}/dp.yml \
                        --dataplane-var ADDRESS=$(hostname -i)
                        
                        
            EOF

            destination = "$${NOMAD_TASK_DIR}/entrypoint.sh"
        }



        template {
            data = <<-EOF
              type: Dataplane
              mesh: default
              name: test-job
              networking:
                address: 127.0.0.1
                advertisedAddress: 127.0.0.1
                inbound:
                - port: 9091
                  servicePort: 9090
                  serviceAddress: 127.0.0.1
                  tags:
                    kuma.io/service: test-job
                    kuma.io/protocol: tcp
                outbound:
                - port: 4567
                  tags:
                    kuma.io/service: test-job
          EOF
            destination = "$${NOMAD_TASK_DIR}/dp.yml"

}
      template {
        data = <<-EOF
        	KUMA_DATAPLANE_RUNTIME_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6IjEiLCJ0eXAiOiJKV1QifQ.eyJOYW1lIjoiIiwiTWVzaCI6ImRlZmF1bHQiLCJUYWdzIjp7fSwiVHlwZSI6IiIsImV4cCI6MjAxMTI2NzE1MSwibmJmIjoxNjk1OTA2ODUxLCJpYXQiOjE2OTU5MDcxNTEsImp0aSI6IjlkZmJkMTQ5LWE2ZjctNDgzYy1iNmE0LWUzMzMzMjcyNjI1MCJ9.P-BNPo7iba50qjHybjufPwdndq5_9R0iHNFogrUW-z63YAcGEwQAmuLtK_AFmehrX_zyb88GDRv81rfeBsvWn9KFudkoHDQyZ7O88SnaljxnQHmnsR2JFu5fvhlKknYOxNfO2IPdIJSlrhhmgc3_1iP3pSoI6HGvnrihnOhw2FlpJXALwdK9z1PytpecUkdrqwladw0G37BDi-J3E2SLmSujkMQMGJeAXdMzCi4l7zRBal1EuXg4BHUJwrRCeWLaTOOPpZNzhXAw0NmH60UfLTJJvZWWeYvGg4SWWS-_Me2sa2iuyAkUIMCQBhiJikwBfDzcXlwFjfeKs73L2HTKCg
          EOF
        destination = "$${NOMAD_SECRETS_DIR}/.env"
        env = true
  }
}
}
}