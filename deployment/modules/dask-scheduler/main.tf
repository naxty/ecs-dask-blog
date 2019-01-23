
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_eip" "scheduler_ip" {
  vpc      = true
}

resource "aws_security_group" "scheduler" {
  name        = "${var.environment}-scheduler-sg"
  description = "Security group to allow inbound/outbound from the scheduler"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    from_port = 8888
    to_port = 8888
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  ingress {
    from_port = 8786
    to_port = 8786
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self = true
  }
  ingress {
    from_port = 8787
    to_port = 8787
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self = true
  }
  egress {
    from_port = 0
    to_port = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Environment = "${var.environment}"
  }
}

data "template_file" "scheduler-userdata" {
  template = "${file("${path.module}/user-data.sh")}"
  vars {
    private_scheduler_ip = "${aws_eip.scheduler_ip.private_ip}"
  }
}

resource "aws_instance" "scheduler" {
  count = "1"

  ami                    = "ami-f976839e"
  instance_type          = "t2.xlarge"
  subnet_id              = "${element(var.public_subnet_ids, 0)}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${var.security_groups_ids}", "${aws_security_group.scheduler.id}"]

  user_data = "${data.template_file.scheduler-userdata.rendered}"

  #associate_public_ip_address = ""
  #ipv6_address_count          = "${var.ipv6_address_count}"
  #ipv6_addresses              = "${var.ipv6_addresses}"

  #ebs_optimized          = "${var.ebs_optimized}"
  #volume_tags            = "${var.volume_tags}"
  #root_block_device      = "${var.root_block_device}"
  #ebs_block_device       = "${var.ebs_block_device}"
  #ephemeral_block_device = "${var.ephemeral_block_device}"

  #source_dest_check                    = "${var.source_dest_check}"
  #disable_api_termination              = "${var.disable_api_termination}"
  #instance_initiated_shutdown_behavior = "${var.instance_initiated_shutdown_behavior}"
  #placement_group                      = "${var.placement_group}"
  #tenancy                              = "${var.tenancy}"

  tags = {
    Name = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = ["private_ip", "root_block_device", "ebs_block_device"]
  }
}

# We need to use an association, otherwise TF runs into a cycle
resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.scheduler.id}"
  allocation_id = "${aws_eip.scheduler_ip.id}"
}
