variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default = [
    "10.0.3.0/24",
    "10.0.4.0/24",
  ]
}

variable "azs" {
  description = "Availability Zones to use"
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
  ]
}

variable "cluster_name" {
  description = "EKS cluster name for dev"
  type        = string
  default     = "tc2-dev-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS dev cluster"
  type        = string
  default     = "1.30"
}

variable "tags" {
  description = "Common tags for dev resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "devops-code-challenge2"
  }
}
