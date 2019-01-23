output "public_scheduler_ip" {
  value = "${aws_eip.scheduler_ip.public_ip}"
}

output "private_scheduler_ip" {
  value = "${aws_eip.scheduler_ip.private_ip}"
}