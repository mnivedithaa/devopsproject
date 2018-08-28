resource "aws_ecs_cluster" "ecs" {
  name = "nimahend-ECS_Cluster"
}

resource "aws_security_group" "nimahend-alb-security-group" {
  name   = "nimahend_alb_security_group"
  vpc_id = "${var.aws_vpc_id}"
}

resource "aws_security_group_rule" "nimahend-albincoming" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.nimahend-alb-security-group.id}"
}

resource "aws_security_group_rule" "nimahend-alboutgoing" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.ecs_security_group.id}"
  security_group_id        = "${aws_security_group.nimahend-alb-security-group.id}"
}

resource "aws_lb" "devops_alb" {
  name            = "nimahend-alb"
  internal        = false
  security_groups = ["${aws_security_group.nimahend-alb-security-group.id}"]
  subnets         = ["${var.multiaz_subnets}"]
}

resource "aws_lb_target_group" "nimahend_devops_target_group" {
  name_prefix = "devops"
  port        = "5002"
  protocol    = "HTTP"
  vpc_id      = "${var.aws_vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = 200
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "nimahend-devops-target-group"
  }
}

resource "aws_lb_listener" "devops_listener" {
  load_balancer_arn = "${aws_lb.devops_alb.arn}"
  port              = "5002"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nimahend_devops_target_group.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "ecs_security_group" {
  name   = "nimahend-ECS SG"
  vpc_id = "${var.aws_vpc_id}"
}

resource "aws_security_group_rule" "nimahend-ecs-incoming" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.ecs_security_group.id}"
  source_security_group_id = "${aws_security_group.nimahend-alb-security-group.id}"
}

resource "aws_security_group_rule" "nimahend-ecs-outgoing" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = "${aws_security_group.ecs_security_group.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_iam_role" "ecs_role" {
  name = "nimahend-ECS_Role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal":
             {
               "Service": "ec2.amazonaws.com"
             },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_policy" {
  name = "nimahend-ECS_Policy"
  role = "${aws_iam_role.ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterContainerInstance",
        "ecs:DeregisterContainerInstance",
        "ecs:SubmitContainerStateChange",
        "ecs:SubmitTaskStateChange",
        "ecs:StartTask"
      ],
      "Resource": "${aws_ecs_cluster.ecs.id}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:StartTelemetrySession",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "nimahend-ECS_Instance_Profile"
  role = "${aws_iam_role.ecs_role.name}"
}

data "template_file" "ecs" {
  template = "${file("${path.module}/ecscluster.tpl")}"

  vars {
    cluster_name = "${aws_ecs_cluster.ecs.name}"
  }
}

data "template_cloudinit_config" "cloudinit" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content      = "${data.template_file.ecs.rendered}"
  }
}

resource "aws_instance" "ecs_instance" {
  ami                    = "${var.ecsami}"
  instance_type          = "t2.micro"
  key_name               = "${var.key_name}"
  subnet_id              = "${var.aws_subnet_id}"
  source_dest_check      = false
  vpc_security_group_ids = ["${aws_security_group.ecs_security_group.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.ecs_instance_profile.name}"
  user_data              = "${data.template_cloudinit_config.cloudinit.rendered}"
}

data "template_file" "devops_config" {
  template = "${file("${path.module}/devops.tpl")}"
}

resource "aws_ecs_task_definition" "devops" {
  family                = "devops"
  container_definitions = "${data.template_file.devops_config.rendered}"
}

resource "aws_ecs_service" "devops" {
  depends_on                         = ["aws_lb_listener.devops_listener"]
  name                               = "devops"
  cluster                            = "${aws_ecs_cluster.ecs.name}"
  desired_count                      = "1"
  task_definition                    = "${aws_ecs_task_definition.devops.family}:${aws_ecs_task_definition.devops.revision}"
  deployment_minimum_healthy_percent = "0"
  iam_role                           = "${aws_iam_role.iam_devops_service_role.name}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.nimahend_devops_target_group.arn}"
    container_name   = "devopsproject"
    container_port   = "5002"
  }
}

resource "aws_iam_role" "iam_devops_service_role" {
  name = "nimahend_iam_devops_service_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_devops_policy_alb" {
  name = "nimahend_iam_devops_alb_policy"
  role = "${aws_iam_role.iam_devops_service_role.id}"

  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement":[
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
