resource "random_string" "suffix" {
  length  = 7
  special = false
  upper   = false
}

locals {
  cluster_type           = var.cluster_name
  network_name           = "${var.cluster_name}-${random_string.suffix.result}"
  subnet_name            = "${var.cluster_name}-subnet"
  master_auth_subnetwork = "${var.cluster_name}-master-subnet"
  pods_range_name        = "ip-range-pods-${random_string.suffix.result}"
  svc_range_name         = "ip-range-svc-${random_string.suffix.result}"
  subnet_names           = [for subnet_self_link in module.gcp-network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
}

# Enable APIs
module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 11.2"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "cloudbuild.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containeranalysis.googleapis.com",
    "containerregistry.googleapis.com",
    "gkehub.googleapis.com",
    "pubsub.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}
provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  project_id                 = var.project_id
  name                       = "${local.cluster_type}-cluster-${random_string.suffix.result}"
  regional                   = true
  region                     = var.region
  zones                      = ["${var.zone}"]
  network                    = module.gcp-network.network_name
  subnetwork                 = local.subnet_names[index(module.gcp-network.subnets_names, local.subnet_name)]
  ip_range_pods              = local.pods_range_name
  ip_range_services          = local.svc_range_name
  http_load_balancing        = true
  horizontal_pod_autoscaling = true
  add_cluster_firewall_rules = false
  default_max_pods_per_node  = 30
  release_channel            = "RAPID"

  node_pools = [
    {
      name                      = "performance-test-node"
      min_count                 = 1
      max_count                 = 100
      local_ssd_count           = 0
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 30
      disk_type                 = "pd-standard"
      image_type                = "COS"
      auto_repair               = true
      auto_upgrade              = true
      service_account           = var.service_account_email
      preemptible               = true
      machine_type              = var.machine_type
      max_pods_per_node         = 48
    },
  ]

  node_pools_oauth_scopes = {
    all = []
    performance-test-node = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_metadata = {
    all                   = {}
    performance-test-node = {}
  }
  node_pools_labels = {
    all = {}
    performance-test-node = {
      performance-test-node = true
    }
  }

  node_pools_tags = {
    performance-test-node = [
      "performance-test-node",
    ]
  }

  istio     = false
  cloudrun  = false
  dns_cache = false

  notification_config_topic = google_pubsub_topic.updates.id

  depends_on = [module.gcp-network]
}

resource "google_pubsub_topic" "updates" {
  name    = "cluster-updates-${random_string.suffix.result}"
  project = var.project_id
}

module "gke_auth" {
  source       = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}