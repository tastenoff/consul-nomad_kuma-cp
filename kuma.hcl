job "kuma" {
  datacenters = ["dc1"]
  type = "service"
  
  group "test-group" {
    network {
      mode = "bridge"
      port dp_server {
        static = 5678
      }
      port api_server {
        static = 5681
      }
    }

    task "kuma" {
      driver = "docker"

      config {
        image = "kumahq/kuma-cp:2.4.1"
        entrypoint = [ "sh" ]
        args  = [ "$${NOMAD_TASK_DIR}/entrypoint.sh" ]
        ports = [ "dp_server", "api_server" ]
      }
      
      env {
        KUMA_GENERAL_TLS_CERT_FILE = "$${NOMAD_SECRETS_DIR}/cert.pem"
        KUMA_GENERAL_TLS_KEY_FILE  = "$${NOMAD_SECRETS_DIR}/key.pem"
      }
      
      template {
        data = <<-EOF
          #!/bin/sh

          kuma-cp run -c {{env "NOMAD_TASK_DIR"}}/conf.yml &

          API_PORT=5681
          echo "Waiting kuma api server to launch on 5681..."
          while ! nc -z localhost $API_PORT; do
            sleep 1
          done

          TOKEN_URL="http://localhost:$API_PORT/global-secrets/admin-user-token"
          while [[ \
            "$(wget -qSO /dev/null $TOKEN_URL 2>&1 | \
              grep HTTP/ | \
              awk '{print $2}')" != "200" \
          ]]; do
            sleep .1
          done
          echo "Api server launched"

          DP_TOKEN=$(wget -qO- \
              --header "Content-Type: application/json" \
              --post-data='{"mesh": "default"}, "validFor": "175200h"}' \
              http://localhost:$API_PORT/tokens/dataplane)
          echo -ne "PUT /v1/kv/kuma/dp_token HTTP/1.1\r\nHost: {{env "NOMAD_IP_dp_server"}}:8500\r\nAccept: */*\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: `echo -n $${DP_TOKEN} | wc -c`\r\n\r\n$${DP_TOKEN}" | \
            nc {{env "NOMAD_IP_dp_server"}} 8500 > /dev/null
          wait
        EOF
        destination = "$${NOMAD_TASK_DIR}/entrypoint.sh"
      }

      template {
        data = <<-EOF
          environment: universal
          mode: standalone

          store:
            type: memory

          apiServer:
            http:
              enabled: true
              interface: 0.0.0.0 #127.0.0.1
            https:
              enabled: true
              interface: 127.0.0.1

          defaults:
            skipMeshCreation: false

          dnsServer:
            serviceVipEnabled: false

          dpServer:
            auth:
              type: none

          access:
            static:
              viewConfigDump:
                groups: ["mesh-system:authenticated"]
              viewClusters:
                groups: ["mesh-system:authenticated"]
              viewStats:
                groups: ["mesh-system:authenticated"]

          proxy:
            gateway:
              globalDownstreamMaxConnections: 50000
        EOF
        destination = "$${NOMAD_TASK_DIR}/conf.yml"
      }
      
      template {
        data = <<-EOF
-----BEGIN CERTIFICATE-----
MIIFDjCCAvagAwIBAgIQPURMmen9uSc+af26+lJzIjANBgkqhkiG9w0BAQsFADAP
MQ0wCwYDVQQDEwRLdW1hMB4XDTIzMDkyODEzMDMxNVoXDTQzMDkyMzEzMDMxNVow
DzENMAsGA1UEAxMES3VtYTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
AK+cTwICgJj13C6OLA6GCHQ66DWC/tAjzmRuAVPD9pbzxISc3GO1zI4GmXiA+whc
ZImP81Ab4vrx9q+LFuigAv0o3AikIC5RNCpgZ8+aB3ATy5AW9fUzAqo1QGev9yHW
8Gs3bycv45q3rro2nvQoeYy7OOqgnF0JOqGmk2MV5n0dDGVLVQ9p7flxFSuqLf2s
QmzkfQwrXtBDPvxqniuWIMG5TA04zIoc5v7PvrX3CX74mqMZUn9Il+SAZ08epPlf
EVKD9X+3mm/D+RywPofARIaJJqa871XB3ycWwwd2BDgXTHJ3ml3HOt9J5WUcUfpC
+iPG0RV8LFx/saMw5j/ip38L454D8mUbAUVZ7A5aoeGERy5+Ni2q3/XZeKoUhvKE
ZU9KW7ASxOcYs36FhoeA0w+0QTbYPWo1IHeE1MZLhSRVjAyKnv59KmwUBdbNzooA
0x6AcAfV50xw9WAYEAXWkY9Y3M3iq3iSXxIFlVscnwSRBWUP8gC+1x4mauLeGt0F
p1DPp3PgJNZaoSc9OIs6AjI6mGmgfCNZnKnFatquE9SY8wINqU3e9ccAwRO7tPqD
MTc76qZOqfRhjkqw2jXaqXgsgWxUiQEr/iGh1h/i7DCiAT9mmyoGqqCaCH+ayIho
g+m/bloUxAQcJCg6Q4nKtRxGoDPUnZQzYya0OTHicH3RAgMBAAGjZjBkMA8GA1Ud
JQQIMAYGBFUdJQAwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUdf+UaIoYivp1
TLPS4h9PpPjbVlowIQYDVR0RBBowGIIWa3VtYS1jcC5zZXJ2aWNlLmNvbnN1bDAN
BgkqhkiG9w0BAQsFAAOCAgEAm2/AMcOw4hvlPeZD+y1rlI1RYBX7ynrvkVCfmAD/
oPgnFYDJQ9nWETEOqrpPOwEDoTqp+j/ZIdjX2UNHK0VYTw1G6J2dcqDNcZOFlttF
mnIJfu8mG/uGT5z8WfFrW0YA4GjjHwO8ag+95n2x7BZE81eE+bCMse8xfYaRRdJm
ZZaQtbKycJJbLzUWYeuoeuWzjWW3bJzEo5OaOTZSrhMhbylv1lQ6icTm59Ub8O2h
j0PaxvK8xeGUVKreBSq5GZZcnpFfbEetVesaOlPIMfHkZRtlRyh3gTo0LcVcnGCW
rz4V+99VNaK0o3rVgt84jmxujtQ6eQ52yf1t5oalpQbJ0FGhLhozV+eQhlzQkKo+
MZ5ZtYEe9+eZHhjzzvwhWuXyNRg+lxo0mMyofF/uqwl8l+eA34QwollygNw6Oeva
71pYi2accNf6tpR2X92eXJm3CcAriuCavyFMxoXVg6mC6Wdn8jCOqfhy5ls3fWOO
ZSCcGRnqoQnkm4UMjTF/ca+JJFF6HJUcAMAsLB+1gq1cZzo1JzkkwDOamZdNGvPy
DcPRdF0h44yzNj4y/CciJvc1dAyxY5rSaGPoNAG86vtQRp6Pr5v+ZeSQhkUOE1Hy
aVU/d35U2wvbLEuFmOnn3LDuc/vdr+Ugg3CktuE9Q3/66d17GYlJZQC5zlOcrhd3
p9Y=
-----END CERTIFICATE-----
        EOF
        destination = "$${NOMAD_SECRETS_DIR}/cert.pem"
      }
      
            template {
        data = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----
        EOF
        destination = "$${NOMAD_SECRETS_DIR}/key.pem"
      }
      
      
      }


      service {
        name = "kuma-cp"
        port = "dp_server"
      }
    
    	


    }
  
  		
  }

