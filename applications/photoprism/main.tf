resource "kubernetes_manifest" "namespace_photoprism" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = "photoprism"
    }
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name      = "photoprism-secrets"
    namespace = "photoprism"
  }

  data = {
    "PHOTOPRISM_ADMIN_PASSWORD" = "${var.photoprism_admin}"
    "PHOTOPRISM_DATABASE_DSN"   = "${var.photoprism_db_connection_string}"
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "statefulset_photoprism_photoprism" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "StatefulSet"
    "metadata" = {
      "name"      = "photoprism"
      "namespace" = "photoprism"
    }
    "spec" = {
      "replicas" = 2
      "selector" = {
        "matchLabels" = {
          "app" = "photoprism"
        }
      }
      "serviceName" = "photoprism"
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "photoprism"
          }
        }
        "spec" = {
          "containers" = [
            {
              "env" = [
                {
                  "name"  = "PHOTOPRISM_DEBUG"
                  "value" = "true"
                },
                {
                  "name"  = "PHOTOPRISM_UID"
                  "value" = "1000"
                },
                {
                  "name"  = "PHOTOPRISM_GID"
                  "value" = "1000"
                },
                {
                  "name"  = "PHOTOPRISM_DISABLE_CHOWN"
                  "value" = "1"
                },
                {
                  "name"  = "PHOTOPRISM_WORKERS"
                  "value" = "1"
                },
                {
                  "name"  = "PHOTOPRISM_DISABLE_TENSORFLOW"
                  "value" = "true"
                },
                {
                  "name"  = "PHOTOPRISM_DATABASE_DRIVER"
                  "value" = "mysql"
                },
                {
                  "name"  = "PHOTOPRISM_HTTP_HOST"
                  "value" = "0.0.0.0"
                },
                {
                  "name"  = "PHOTOPRISM_HTTP_PORT"
                  "value" = "2342"
                },
              ]
              "envFrom" = [
                {
                  "secretRef" = {
                    "name"     = "photoprism-secrets"
                    "optional" = false
                  }
                },
              ]
              "image" = "photoprism/photoprism:latest"
              "name"  = "photoprism"
              "ports" = [
                {
                  "containerPort" = 2342
                  "name"          = "http"
                },
              ]
              "readinessProbe" = {
                "httpGet" = {
                  "path" = "/api/v1/status"
                  "port" = "http"
                }
              }
              "resources" = {
                "limits" = {
                  "cpu"    = "1"
                  "memory" = "2560Mi"
                }
                "requests" = {
                  "cpu"    = "1"
                  "memory" = "2Gi"
                }
              }
              "volumeMounts" = [
                {
                  "mountPath" = "/photoprism/originals"
                  "name"      = "originals"
                },
                {
                  "mountPath" = "/photoprism/import"
                  "name"      = "import"
                },
                {
                  "mountPath" = "/photoprism/storage"
                  "name"      = "storage"
                },
              ]
            },
          ]
          "volumes" = [
            {
              "name" = "originals"
              "nfs" = {
                "path"   = "/export/home-lab-nas-runtime/photoprism/originals"
                "server" = "192.168.2.10"
              }
            },
            {
              "name" = "import"
              "nfs" = {
                "path"   = "/export/home-lab-nas-runtime/photoprism/import"
                "server" = "192.168.2.10"
              }
            },
            {
              "name" = "storage"
              "nfs" = {
                "path"   = "/export/home-lab-nas-runtime/photoprism/storage"
                "server" = "192.168.2.10"
              }
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_photoprism_photoprism" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name"      = "photoprism"
      "namespace" = "photoprism"
    }
    "spec" = {
      "ports" = [
        {
          "name"       = "http"
          "port"       = 80
          "protocol"   = "TCP"
          "targetPort" = "http"
        },
      ]
      "selector" = {
        "app" = "photoprism"
      }
      "type" = "ClusterIP"
    }
  }
}

resource "kubernetes_manifest" "ingress_photoprism_photoprism" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "annotations" = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-production"
        "kubernetes.io/ingress.class"    = "traefik"
      }
      "labels" = {
        "app" = "photoprism"
      }
      "name"      = "photoprism"
      "namespace" = "photoprism"
    }
    "spec" = {
      "rules" = [
        {
          "host" = "photoprism.bounteous.home-lab.begoodguys.ovh"
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "photoprism"
                    "port" = {
                      "number" = 80
                    }
                  }
                }
                "path"     = "/"
                "pathType" = "Prefix"
              },
            ]
          }
        },
      ]
      "tls" = [
        {
          "hosts" = [
            "photoprism.bounteous.home-lab.begoodguys.ovh",
          ]
          "secretName" = "letsencryptk3s-bounteous-photoprism-home-lab-ovh-tls-prod"
        },
      ]
    }
  }
}
