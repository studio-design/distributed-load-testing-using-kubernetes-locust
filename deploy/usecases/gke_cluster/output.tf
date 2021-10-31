output "kubeconfig_raw" {
  value     = module.gke_auth.kubeconfig_raw
  sensitive = true
}

output "cluster_name" {
  value = module.gke.name
}

output "cluster_region" {
  value = module.gke.region
}