output "public_scheduler_ip" {
  value = "${module.dask-scheduler.public_scheduler_ip}"
}

output "private_scheduler_ip" {
  value = "${module.dask-scheduler.private_scheduler_ip}"
}