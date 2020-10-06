resource "kubernetes_service_account" "efs_provisioner" {
  metadata {
    name      = "efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "efs_provisioner_runner" {
  metadata {
    name = "efs-provisioner-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_cluster_role_binding" "run_efs_provisioner" {
  metadata {
    name = "run-efs-provisioner"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "efs-provisioner-runner"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }
}

resource "kubernetes_role" "leader_locking_efs_provisioner" {
  metadata {
    name      = "leader-locking-efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }
  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "leader_locking_efs_provisioner" {
  metadata {
    name      = "leader-locking-efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "leader-locking-efs-provisioner"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_config_map" "efs_provisioner" {
  metadata {
    name      = "efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }

  data = {
    "file.system.id"   = module.efs.id
    "aws.region"       = var.region
    "provisioner.name" = "example.com/aws-efs"
    "dns.name"         = ""
  }
}

resource "kubernetes_deployment" "efs_provisioner" {
  metadata {
    name      = "efs-provisioner"
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
    labels = {
      name = "efs-provisioner"
    }
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "efs-provisioner"
      }
    }

    template {
      metadata {
        labels = {
          app = "efs-provisioner"
        }
      }

      spec {
        service_account_name            = "efs-provisioner"
        automount_service_account_token = true

        container {
          name  = "efs-provisioner"
          image = "quay.io/external_storage/efs-provisioner:latest"

          env {
            name = "FILE_SYSTEM_ID"
            value_from {
              config_map_key_ref {
                name = "efs-provisioner"
                key  = "file.system.id"
              }
            }
          }
          env {
            name = "AWS_REGION"
            value_from {
              config_map_key_ref {
                name = "efs-provisioner"
                key  = "aws.region"
              }
            }
          }
          env {
            name = "DNS_NAME"
            value_from {
              config_map_key_ref {
                name = "efs-provisioner"
                key  = "dns.name"
              }
            }
          }
          env {
            name = "PROVISIONER_NAME"
            value_from {
              config_map_key_ref {
                name = "efs-provisioner"
                key  = "provisioner.name"
              }
            }
          }

          volume_mount {
            name       = "pv-volume"
            mount_path = "/persistentvolumes"
          }

        }

        volume {
          name = "pv-volume"
          nfs {
            server = module.efs.dns_name
            path   = "/"
          }
        }
      }
    }
  }
}

resource "kubernetes_storage_class" "aws_efs" {
  metadata {
    name = "aws-efs"
  }
  storage_provisioner = "example.com/aws-efs"
}

resource "kubernetes_persistent_volume_claim" "efs" {
  metadata {
    name = "efs"
    annotations = {
      "volume.beta.kubernetes.io/storage-class" = kubernetes_storage_class.aws_efs.metadata.0.name
    }
    namespace = kubernetes_namespace.dbt_cloud.metadata.0.name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Mi"
      }
    }
  }
}
