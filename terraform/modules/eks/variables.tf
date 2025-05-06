variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "region" {
  description = "AWS region to deploy the EKS cluster"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to launch EKS cluster and nodes in"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster should be deployed"
  type        = string
}