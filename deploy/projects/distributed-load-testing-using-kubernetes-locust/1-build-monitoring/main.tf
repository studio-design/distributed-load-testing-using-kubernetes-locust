terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.90.0"
    }
  }
}

provider "google" {
  project     = var.PROJECT_ID
  credentials = file(var.GOOGLE_APPLICATION_CREDENTIALS)

  region = var.REGION
  zone   = var.ZONE
}

provider "google-beta" {
  project     = var.PROJECT_ID
  credentials = file(var.GOOGLE_APPLICATION_CREDENTIALS)

  region = var.REGION
  zone   = var.ZONE
}
provider "helm" {
  kubernetes {
    config_path = "../0-build-cluster/kubeconfig"
  }
}
resource "null_resource" "helm_updater" {
  provisioner "local-exec" {
    command = <<EOT
        helm repo add stable https://charts.helm.sh/stable
        helm repo add bitnami https://charts.bitnami.com/bitnami
        helm repo add grafana https://grafana.github.io/helm-charts
        helm repo add deliveryhero https://charts.deliveryhero.io/
        helm repo update
    EOT
  }
}

# resource "helm_release" "influxdb" {
#   name  = "influxdb"
#   chart = "bitnami/influxdb"

#   values = [
#     "${file("values/influxdb.yaml")}"
#   ]
# }

# resource "helm_release" "grafana_release" {
#   depends_on = [
#     resource.helm_release.influxdb
#   ]
#   name             = "grafana"
#   chart            = "bitnami/grafana"
#   create_namespace = "false"

#   values = [
#     "${file("values/grafana.yaml")}"
#   ]
# }
