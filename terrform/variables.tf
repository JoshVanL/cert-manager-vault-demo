variable "vault_server" {
  description = "Address for Vault"
  default     = "vault.vault:8200"
}

variable "k8s_host" {
  description = "Address for Kubernetes"
  default     = "10.96.0.1:443"
}

variable "service_names" {
  description = "Names for services"
  type        = list
  default     = ["service-a", "service-b"]
}
