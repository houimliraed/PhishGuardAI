# Kubernetes provider configuration
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Get auth token for Kubernetes
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

# Create default namespace
resource "kubernetes_namespace" "phishguard" {
  metadata {
    name = "phishguard"
  }

  depends_on = [aws_eks_node_group.main]
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "phishguard-backend"
    namespace = kubernetes_namespace.phishguard.metadata[0].name
    labels = {
      app = "phishguard-backend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "phishguard-backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "phishguard-backend"
        }
      }

      spec {
        container {
          image             = var.ecr_app_image
          name              = "backend"
          image_pull_policy = "Always"

          port {
            container_port = 8000
            name           = "http"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        image_pull_secrets {
          name = kubernetes_secret.ecr_secret.metadata[0].name
        }
      }
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# Backend Service
resource "kubernetes_service" "backend" {
  metadata {
    name      = "phishguard-backend"
    namespace = kubernetes_namespace.phishguard.metadata[0].name
  }

  spec {
    selector = {
      app = "phishguard-backend"
    }

    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.backend]
}

# Ingress resource to expose via ALB
resource "kubernetes_ingress_v1" "backend" {
  metadata {
    name      = "phishguard-backend-ingress"
    namespace = kubernetes_namespace.phishguard.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/load-balancer-name" = aws_lb.main.name
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.backend]
}

# Secret for ECR authentication
resource "kubernetes_secret" "ecr_secret" {
  metadata {
    name      = "ecr-secret"
    namespace = kubernetes_namespace.phishguard.metadata[0].name
  }

  type = "kubernetes.io/dockercfg"

  data = {
    ".dockercfg" = jsonencode({
      "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com" = {
        auth = base64encode("AWS:${data.aws_eks_cluster_auth.main.token}")
      }
    })
  }

  depends_on = [kubernetes_namespace.phishguard]
}

# Outputs
output "backend_service_name" {
  value       = kubernetes_service.backend.metadata[0].name
  description = "Name of the backend Kubernetes service"
}

output "ingress_hostname" {
  value       = try(kubernetes_ingress_v1.backend.status[0].load_balancer[0].ingress[0].hostname, "")
  description = "Ingress hostname for accessing the backend"
}
