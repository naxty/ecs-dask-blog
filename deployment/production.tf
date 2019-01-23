locals {
  production_availability_zones = [
    "eu-west-2a"
  ]
  enviroment = "dask-fargate"
  ssh_key_name = "scheduler-key"
}

provider "aws" {
  region = "${var.region}"
}

resource "aws_key_pair" "key" {
  key_name = "${local.ssh_key_name}"
  public_key = "${file("scheduler.key.pub")}"
}


module "networking" {
  source = "./modules/networking"
  environment = "${local.enviroment}"
  vpc_cidr = "10.0.0.0/16"
  public_subnets_cidr = [
    "10.0.1.0/24"]
  private_subnets_cidr = [
    "10.0.10.0/24"]
  region = "${var.region}"
  availability_zones = "${local.production_availability_zones}"
}

module "dask-scheduler" {
  source = "modules/dask-scheduler"
  environment = "${local.enviroment}"
  vpc_id = "${module.networking.vpc_id}"
  availability_zones = "${local.production_availability_zones}"
  subnets_ids = [
    "${module.networking.private_subnets_id}"]
  public_subnet_ids = [
    "${module.networking.public_subnets_id}"]

  security_groups_ids = [
    "${module.networking.security_groups_ids}"
  ]
  key_name = "${local.ssh_key_name}"
}

module "dask-worker" {
  source = "./modules/dask-worker"
  environment = "${local.enviroment}"
  vpc_id = "${module.networking.vpc_id}"
  availability_zones = "${local.production_availability_zones}"
  subnets_ids = [
    "${module.networking.private_subnets_id}"]
  security_groups_ids = [
    "${module.networking.security_groups_ids}"
  ]
  dask_image = "daskdev/dask"
  worker_count = 5
  scheduler_ip = "${module.dask-scheduler.private_scheduler_ip}"
}

