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
module "gke" {
  source                = "../../../usecases/gke_cluster"
  cluster_name          = var.CLUSTER_NAME
  project_id            = var.PROJECT_ID
  region                = var.REGION
  zone                  = var.ZONE
  service_account_email = var.SERVICE_ACCOUNT_EMAIL
  machine_type          = var.MACHINE_TYPE
}

# kubeconfig file for loading secret information into modules from different terraform commands
# How to retrive kubeconfig
# https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/master/examples/simple_regional_with_kubeconfig/outputs.tf
resource "local_file" "kubeconfigfile" {
  content  = module.gke.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
}

# Build a script to configure gcloud command for the newly created GKE cluster.
resource "local_file" "cluster_name" {
  content         = <<EOT
#/bin/bash -x
gcloud container clusters get-credentials ${module.gke.cluster_name} --zone=${module.gke.cluster_region}
EOT
  filename        = "${path.module}/gcloud_conf.sh"
  file_permission = "0755"
}

# Generate short cut script for forwarding Locust master port to the local machine
resource "local_file" "locust_connect_sh" {
  content         = <<EOT
#/bin/bash -x
# locust master port forwarding
gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${module.gke.cluster_region} --project ${var.PROJECT_ID} \
 && kubectl port-forward $(kubectl get pod --selector="app.kubernetes.io/instance=locust-cluster,app.kubernetes.io/name=locust,component=master,load_test=locust-cluster" --output jsonpath='{.items[0].metadata.name}') 8089:8089 
EOT
  filename        = "${path.module}/locust_connect.sh"
  file_permission = "0755"
}