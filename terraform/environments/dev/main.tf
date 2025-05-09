terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.30.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"  # Используем конфиг k3s
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:latest"
          port {
            container_port = 61111  # Используем ваш кастомный порт
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name = "nginx-config"
  }

  data = {
    "default.conf" = <<-EOT
      server {
          listen       61111;
          server_name  localhost;
          location / {
              root   /usr/share/nginx/html;
              index  index.html index.htm;
          }
      }
    EOT
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      app = kubernetes_deployment.nginx.metadata[0].labels.app
    }
    port {
      port        = 61111
      target_port = 61111
      node_port   = 32000  # Фиксируем ваш порт
    }
    type = "NodePort"
  }
}
