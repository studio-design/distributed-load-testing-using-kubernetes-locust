terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.90.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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

provider "kubernetes" {
  config_path = "../0-build-cluster/kubeconfig"
}

provider "kubectl" {
  load_config_file = true
  config_path      = "../0-build-cluster/kubeconfig"
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

# Test script to be stored in the configmap.
# In this way, the custom locust image is not necessarily to be created each time the load script is updated.
resource "kubernetes_config_map" "loadtest-locustfile" {
  metadata {
    name = "loadtest-locustfile"
  }

  data = {
    "main.py" = "${file("${path.module}/../../../../locust/main.py")}"
  }
}

# Lib Directory
# Libraries for the loading test are also configurable in the config map in this way.
locals {
  loadtest_lib_directory_config = "../../../../locust/lib"
}
resource "kubernetes_config_map" "loadtest-lib" {
  metadata {
    name = "loadtest-lib"
  }

  # Load all *.py files under the directory
  data = {
    for f in fileset(local.loadtest_lib_directory_config, "*.py") :
    f => file(join("/", [local.loadtest_lib_directory_config, f]))
  }
}

resource "helm_release" "locust-cluster" {
  name    = "locust-cluster"
  chart   = "deliveryhero/locust"
  version = "0.21.0"

  values = [
    replace("${file("../../../../locust/values.yaml")}", "[TARGET_HOST]", var.TARGET_HOST)
  ]
}