terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_network" "app_network" {
  name = "app-network"
  driver = "bridge"
}

resource "docker_image" "postgres" {
  name = "postgres"
  build {
    context    = "./sql"
    tag        = ["postgres:latest"]
    dockerfile = "Dockerfile"
  }
}

resource "docker_container" "postgres" {
  image = docker_image.postgres.image_id
  name  = "meu-postgres"
  env = [
    "POSTGRES_DB=${var.POSTGRES_DB}",
    "POSTGRES_USER=${var.POSTGRES_USER}",
    "POSTGRES_PASSWORD=${var.POSTGRES_PASSWORD}"
  ]
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 5432
    external = 5432 
  }
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = "postgres_data"
  }
  restart    = "always"
}

resource "docker_image" "backend" {
  name         = "backend"
  build {
    context = "./backend"
    tag = ["backend:latest"]
    dockerfile = "Dockerfile"
  }
  keep_locally = false
}

resource "docker_container" "backend" {
  image = docker_image.backend.image_id
  name  = "backend"
  env = [
    "PORT=${var.PORT}",
    "DB_USER=${var.POSTGRES_USER}",
    "DB_PASSWORD=${var.POSTGRES_PASSWORD}",
    "DB_PORT=${var.DB_PORT}",
    "HOST=${var.HOST}",
  ]
  networks_advanced {
    name = docker_network.app_network.name
  }
   ports {
    internal = 3000
    external = 3000 
  }
  restart    = "always"
  depends_on = [docker_container.postgres]
}

resource "docker_image" "frontend" {
  name = "frontend"
  build {
     context = "./frontend"
     tag = ["frontend:latest"]
     dockerfile = "Dockerfile"
  }
  keep_locally = false
}

resource "docker_container" "frontend" {
  image = docker_image.frontend.image_id
  name  = "frontend"
  networks_advanced {
    name = docker_network.app_network.name
  }
  ports {
    internal = 80
    external = 80 
  }
  restart    = "always"
  depends_on = [ docker_container.backend, docker_container.postgres ]
}

# resource "docker_image" "prometheus" {
#   name = "prom/prometheus"
#   keep_locally = false
# }

# resource "docker_container" "prometheus" {
#   image = docker_image.prometheus.image_id
#   name = "prometheus"
#   ports {
#     internal = 9090
#     external = 9090
#   }
#     restart    = "always"
#     networks_advanced {
#     name = docker_network.app_network.name
#   }
#    volumes {
#     container_path = "/etc/prometheus/prometheus.yml"
#     host_path      = file("${path.module}/prometheus.yml") 
#     read_only      = true
#   }
#   command = ["--config.file=/etc/prometheus/prometheus.yml"]
# }

# resource "docker_image" "grafana" {
#   name = "grafana/grafana"
#   keep_locally = false
# }

# resource "docker_container" "grafana" {
#   image = docker_image.grafana.image_id
#   name = "grafana"
#   ports {
#     internal = 3000
#     external = 4000
#   }
#   restart    = "always"
#   networks_advanced {
#     name = docker_network.app_network.name
#   }
#   volumes {
#     container_path = "/var/lib/grafana"
#     host_path      = "grafana_storage" 
#   }
#   depends_on = [ docker_container.prometheus ]
# }

# resource "docker_image" "cadvisor" {
#   name = "gcr.io/cadvisor/cadvisor:latest"
#   keep_locally = false 
# }

# resource "docker_container" "cadvisor" {
#   image = docker_image.cadvisor.image_id
#   name = "cadvisor"
#   ports {
#     internal = 8080
#     external = 8080
#   }
#   user = "root"
#   volumes {
#     container_path = "/rootfs"
#     host_path      = "/"
#     read_only      = true
#   }
#   volumes {
#     container_path = "/var/run"
#     host_path      = "/var/run"
#     read_only      = false
#   }
#   volumes {
#     container_path = "/sys"
#     host_path      = "/sys"
#     read_only      = true
#   }
#   volumes {
#     container_path = "/var/run/docker.sock"
#     host_path      = "/var/run/docker.sock"
#     read_only      = false
#   }
#}

output "web_url" {
  value = "http://localhost:${docker_container.frontend.ports[0].external}"
}
