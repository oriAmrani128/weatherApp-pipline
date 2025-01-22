variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-008cf0ba67e6e2366"
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS deployment"
  type        = list(string)
  default     = ["subnet-0695f8a4c4a1fbf9d", "subnet-0c69c22d4c08d0f4e"]
}

variable "project" {
  description = "Project name for tagging and resource naming"
  type        = string
  default     = "my-project"
}

variable "env" {
  description = "Environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "eks-cluster-node-group"
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t2.small"]
}

variable "node_group_scaling_config" {
  description = "Node group scaling configuration"
  type        = map(number)
  default     = {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Terraform = "true"
  }
}
