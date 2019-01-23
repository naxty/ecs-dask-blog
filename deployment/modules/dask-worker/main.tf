resource "aws_cloudwatch_log_group" "dask_ecs" {
  name = "dask"

  tags {
    Environment = "${var.environment}"
    Application = "Dask"
  }
}
resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs-cluster"
}

data "template_file" "fargate_task_service" {
  template = "${file("${path.module}/tasks/fargate_task_definition.json")}"

  vars {
    dask_image = "${var.dask_image}"
    scheduler_ip = "${var.scheduler_ip}"
    REGION = "${var.region}"
    log_group = "${aws_cloudwatch_log_group.dask_ecs.name}"

  }
}

resource "aws_ecs_task_definition" "fargate_service" {
  family = "${var.environment}_fargate"
  container_definitions = "${data.template_file.fargate_task_service.rendered}"
  requires_compatibilities = [
    "FARGATE"]
  network_mode = "awsvpc"
  cpu = "4096"
  memory = "8192"
  execution_role_arn = "${aws_iam_role.ecs_execution_role.arn}"
  task_role_arn = "${aws_iam_role.ecs_execution_role.arn}"

}

resource "aws_iam_role_policy" "s3_policy" {
  name = "ecs_execution_role_policy"
  policy = "${file("${path.module}/policies/s3-policy.json")}"
  role = "${aws_iam_role.ecs_execution_role.id}"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_task_execution_role"
  assume_role_policy = "${file("${path.module}/policies/ecs-job-service-execution-role.json")}"
}

resource "aws_security_group" "ecs_service" {
  vpc_id = "${var.vpc_id}"
  name = "${var.environment}-ecs-service-sg"
  description = "Allow egress from container"


  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Name = "${var.environment}-ecs-service-sg"
    Environment = "${var.environment}"
  }
}

data "aws_ecs_task_definition" "fargate_service" {
  task_definition = "${aws_ecs_task_definition.fargate_service.family}"
  depends_on = [
    "aws_ecs_task_definition.fargate_service"]
}

resource "aws_ecs_service" "fargate_service" {
  name = "${var.environment}-fargate_service"
  task_definition = "${aws_ecs_task_definition.fargate_service.family}:${max("${aws_ecs_task_definition.fargate_service.revision}", "${data.aws_ecs_task_definition.fargate_service.revision}")}"
  desired_count = "${var.worker_count}"
  launch_type = "FARGATE"
  cluster = "${aws_ecs_cluster.cluster.id}"

  network_configuration {
    security_groups = [
      "${var.security_groups_ids}",
      "${aws_security_group.ecs_service.id}"]
    subnets = [
      "${var.subnets_ids}"]
    assign_public_ip = false
  }
}
