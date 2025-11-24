# Database Module - Kubernetes PostgreSQL Deployment

# Create namespace for database
resource "kubernetes_namespace" "database" {
  metadata {
    name = var.namespace
    labels = merge(
      var.tags,
      {
        name = var.namespace
      }
    )
  }
}

# Create persistent volume claim for database storage
resource "kubernetes_persistent_volume_claim" "database" {
  metadata {
    name      = "${var.database_name}-pvc"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    storage_class_name = var.storage_class
  }
}

# Create secret for database credentials
resource "kubernetes_secret" "database" {
  metadata {
    name      = "${var.database_name}-secret"
    namespace = kubernetes_namespace.database.metadata[0].name
  }

  data = {
    postgres-password = var.database_password
    postgres-user     = var.database_user
  }

  type = "Opaque"
}

# Deploy PostgreSQL database
resource "kubernetes_deployment" "database" {
  metadata {
    name      = var.database_name
    namespace = kubernetes_namespace.database.metadata[0].name
    labels = merge(
      var.tags,
      {
        app = var.database_name
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.database_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.database_name
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:${var.postgres_version}"

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database.metadata[0].name
                key  = "postgres-password"
              }
            }
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.database.metadata[0].name
                key  = "postgres-user"
              }
            }
          }

          env {
            name  = "POSTGRES_DB"
            value = var.database_name
          }

          port {
            container_port = 5432
            name          = "postgres"
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.database.metadata[0].name
          }
        }
      }
    }
  }
}

# Create service for database
resource "kubernetes_service" "database" {
  metadata {
    name      = var.database_name
    namespace = kubernetes_namespace.database.metadata[0].name
    labels = {
      app = var.database_name
    }
  }

  spec {
    selector = {
      app = var.database_name
    }

    port {
      port        = 5432
      target_port = 5432
      protocol    = "TCP"
    }

    type = var.service_type
  }
}
