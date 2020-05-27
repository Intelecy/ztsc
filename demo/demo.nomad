job "ztsc-demo" {
  datacenters = ["azure"]
  type        = "service"

  group "demo1" {
    count = 1

    task "zerotier" {
      driver = "docker"

      config {
        image   = "intelecy/ztsc:latest"
        devices = [
          {
            host_path      = "/dev/net/tun",
            container_path = "/dev/net/tun",
          },
        ]
        cap_add = [
          "NET_ADMIN",
          "SYS_ADMIN",
        ]
        volumes = [
          "Caddyfile:/etc/caddy/Caddyfile:ro",
        ]
      }

      env {
        // replace with actual values
        ZT_NETWORK_ID      = "001122334455667788"
        ZT_IDENTITY_PUBLIC = "0123456789:0:xxx"
        ZT_IDENTITY_SECRET = "0123456789:0:xxx:yyy"
      }

      template {
        data = <<EOH
http://
reverse_proxy {$NOMAD_ADDR_unsplash_http}
EOH

        destination = "Caddyfile"
      }

      lifecycle {
        sidecar = true
        hook    = "prestart"
      }
    }

    task "unsplash" {
      driver = "docker"

      env {}

      resources {
        network {
          port "http" {}
        }
      }

      config {
        image = "intelecy/ztsc-demo:latest"

        args = [
          "-port",
          "${NOMAD_PORT_http}",
        ]
      }
    }
  }
}
