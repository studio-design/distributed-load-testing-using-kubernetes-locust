// Global variables
variable "cluster_name" {
  default     = ""
  description = "Cluster name stored in GCR. eg: distributed-load-testing-using-kubernetes-locust"
}

variable "project_id" {
  type    = string
  default = ""
}

variable "region" {
  default     = "us-central1"
  description = "(Required) GKE Region."
}

variable "zone" {
  default     = "us-central1-c"
  description = "(Required) GKE Zone"
}

// Service Account
variable "service_account_email" {
  type        = string
  default     = ""
  description = "Service Account email"
}

variable "machine_type" {
  default     = "n2-standard-2"
  description = "(Required) GKE Zone"
}