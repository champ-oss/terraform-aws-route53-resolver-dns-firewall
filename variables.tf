variable "allow_domains" {
  description = "List of domains to allow."
  type        = list(string)
  default     = []
}

variable "deny_domains" {
  description = "List of domains to block."
  type        = list(string)
  default     = []
}

variable "enabled" {
  description = "Whether to enable the resources."
  type        = bool
  default     = true
}

variable "git" {
  description = "Git repository name for naming resources."
  type        = string
  default     = "terraform-aws-resolver-dns-firewall"
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

variable "association_priority" {
  description = "Priority of the firewall rule group association."
  type        = number
  default     = 100
}

variable "mutation_protection" {
  description = "Whether to enable mutation protection on the firewall rule group association."
  type        = string
  default     = "DISABLED"
}

variable "enable_query_logging" {
  description = "Enable Route 53 Resolver DNS query logging."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
  default     = 30
}

variable "vpc_id" {
  description = "VPC ID to associate the firewall rule group and query logging."
  type        = string
  default     = ""
}

variable "enabled_r53_resolver_firewall" {
  description = "Whether to enable the Route 53 Resolver DNS firewall."
  type        = bool
  default     = false
}