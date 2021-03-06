variable "project_name" {
  type        = "string"
  description = "The name of the service to store secrets for."
}

variable "secrets" {
  type        = "map"
  description = "A map of secrets to make available to the service."
}

variable "disabled_services" {
  type        = "list"
  description = "list of disabled services."
  default     = []
}
