variable "region" {
  default = "eu-central-1"
}

variable "stage" {
  default = "test"
}

variable "organization_name" {
  description = "Is used to generate self-signed certificate"
}

variable "instance_type" {
  default = "t2.small"
}

variable "asg_desired_capacity" {
  default = 3
}

variable "root_volume_size" {
  default = 5
}

variable "cidr" {
  description = "CIDR range for the VPC"
}

variable "private_subnets" {
  description = "List of private Subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public Subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Single NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS Hostname"
  type        = bool
  default     = true
}

variable "cloudflare_email" {
  description = "CloudFlare Email"
}

variable "cloudflare_api_key" {
  description = "Cloudflare API key"
}

variable "cloudflare_zone" {
  default = "example.com"
}

variable "cloudflare_host" {
  default = "www"
}

variable "cloudflare_ttl" {
  default = 1
}

variable "cloudflare_proxied" {
  default = true
}