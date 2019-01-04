variable "environment" {
  description = "The environment"
}

variable "vpc_id" {
  description = "The VPC id"
}

variable "availability_zones" {
  type = "list"
  description = "The azs to use"
}

variable "security_groups_ids" {
  type = "list"
  description = "The SGs to use"
}

variable "subnets_ids" {
  type = "list"
  description = "The private subnets to use"
}

variable "scheduler_ip" {
  description = "IP of the scheduler"
}

variable "fargate_image" {
  description = "Image name in ecr of fargate_image"
}

variable "fargate_count" {
  description = "Amount of fargate tasks"
  default = "0"
}

variable "region" {
  description = "AWS region"
  default = "eu-west-2"
}
