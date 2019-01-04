locals {
  production_availability_zones = [
    "eu-west-2a"
  ]
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "key" {
  key_name = "production_key"
  public_key = "${file("production_key.pub")}"
}


module "networking" {
  source = "./modules/networking"
  environment = "production"
  vpc_cidr = "10.0.0.0/16"
  public_subnets_cidr = [
    "10.0.1.0/24"]
  private_subnets_cidr = [
    "10.0.10.0/24"]
  region = "${var.region}"
  availability_zones = "${local.production_availability_zones}"
  key_name = "production_key"
}

module "ec2" {
  source = "./modules/ec2"
  environment = "production"
  vpc_id = "${module.networking.vpc_id}"
  availability_zones = [
    "eu-west-2a"]
  subnets_ids = [
    "${module.networking.private_subnets_id}"]
  public_subnet_ids = [
    "${module.networking.public_subnets_id}"]

  security_groups_ids = [
    "${module.networking.security_groups_ids}"
  ]
  key_name = "production_key"
}

module "ecs" {
  source = "./modules/ecs"
  environment = "production"
  vpc_id = "${module.networking.vpc_id}"
  availability_zones = [
    "eu-west-2a"]
  subnets_ids = [
    "${module.networking.private_subnets_id}"]

  security_groups_ids = [
    "${module.networking.security_groups_ids}"
  ]

  fargate_image = "daskdev/dask"
  fargate_count = 50
  scheduler_ip = "${module.ec2.scheduler_ip}"
}

