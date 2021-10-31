// Global variables
variable "CLUSTER_NAME" {
  default     = ""
  description = "Cluster name stored in GCR. eg: distributed-load-testing-using-kubernetes-locust"
}
variable "PROJECT_ID" {
  type    = string
  default = ""
}

variable "REGION" {
  default     = "us-central1"
  description = "(Required) GKE Region."
}

variable "ZONE" {
  default     = "us-central1-c"
  description = "(Required) GKE Zone"
}

variable "MACHINE_TYPE" {
  default     = "n2-standard-2"
  description = "(Required) GKE Zone"
}

// Service Account
variable "SERVICE_ACCOUNT_EMAIL" {
  type        = string
  default     = ""
  description = "Service Account email"
}

variable "GOOGLE_APPLICATION_CREDENTIALS" {
  type        = string
  default     = ""
  description = "Service Account json file absolute path"
}
variable "TARGET_HOST" {
  type        = string
  default     = ""
  description = "Target Host"
}
