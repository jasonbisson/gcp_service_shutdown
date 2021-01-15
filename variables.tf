

variable "project_id" {
  description = "Project ID to hold GCF"
}

variable "environment" {
  description = "Unique environment name to link the whole deployment"
  default = "service-monitor"
}

variable "region" {
  description = "Region where cloud function is deployed"
  type = "string"
  default = "us-central1"  
}

variable "org_id" {
  description = "Organization ID to monitor"
}

variable "enable_apis" {
  description = "Whether to actually enable the APIs. If false, this module is a no-op."
  default     = "true"
}

variable "activate_apis" {
  description = "The list of apis to activate within the project"
  default     = ["pubsub.googleapis.com", "servicemanagement.googleapis.com", "cloudfunctions.googleapis.com"]
  type        = list(string)
}

variable "disable_services_on_destroy" {
  description = "Whether project services will be disabled when the resources are destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_on_destroy"
  default     = "false"
  type        = "string"
}

variable "disable_dependent_services" {
  description = "Whether services that are enabled and which depend on this service should also be disabled when this service is destroyed. https://www.terraform.io/docs/providers/google/r/google_project_service.html#disable_dependent_services"
  default     = "false"
  type        = "string"
}

variable "blocked_apis_list" {
  type        = "list"
  description = "list of APIs to prevent being used"
}

variable "runtime" {
  description = "Runtime environment for cloud function"
  type  = "string"
  default = "nodejs12"
}

variable "function_event_trigger_failure_policy_retry" {
  type        = "string"
  default     = false
  description = "A toggle to determine if the function should be retried on failure."
}

variable "zip_name" {
  description = "The Zip file for Cloud Function"
  default     = "service_monitor.zip"
}