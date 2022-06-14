terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    // TODO: configure infrastructure details in env vars.
    bucket         = "footystats-terraform-state" // Pre-existing bucket to store tfstate
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "footystats-terraform" // Pre-existing Dynamo DB for state locking https://www.terraform.io/language/state/locking
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_ecr_repository" "footystats_web_ecr_repo" {
  name = "footystats_web_ecr_repo"
}

resource "aws_ecs_cluster" "footystats_cluster" {
  name = "footystats_cluster"
}

resource "aws_ecs_task_definition" "footystats_web_task" {
  family = "footystats_web_task"
  container_definitions = jsonencode([
    {
      "name" : "footystats_web_task",
      "image" : "${aws_ecr_repository.footystats_web_ecr_repo.repository_url}",
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "memory" : 512,
      "cpu" : 256
    }
  ])
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_ecs_service" "footystats_web_service" {
  name                               = "footystats_web_service"                        # Naming our service
  cluster                            = aws_ecs_cluster.footystats_cluster.id           # Referencing our created Cluster
  task_definition                    = aws_ecs_task_definition.footystats_web_task.arn # Referencing the task our service will spin up
  launch_type                        = "FARGATE"
  desired_count                      = 1   # Setting the number of containers we want deployed
  deployment_minimum_healthy_percent = 0   # Allow for no instance on deployment for roll over, may cause outage (503).
  deployment_maximum_percent         = 200 # Allow for two instances on deployment, to roll over, may cause multiple different versions.

  load_balancer {
    target_group_arn = aws_lb_target_group.footystats_web_target_group.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.footystats_web_task.family
    container_port   = 80 # Specifying the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true                                                               # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.footystats_web_service_security_group.id}"] # Setting the security group
  }
}

resource "aws_security_group" "footystats_web_service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.footystats_web_alb_security_group.id}"]
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "ap-southeast-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "ap-southeast-2b"
}

resource "aws_default_subnet" "default_subnet_c" {
  availability_zone = "ap-southeast-2c"
}

resource "aws_alb" "footystats_web_alb" {
  name               = "footystats-web-alb"
  load_balancer_type = "application"
  subnets = [
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}",
    "${aws_default_subnet.default_subnet_c.id}"
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.footystats_web_alb_security_group.id}"]
}

# Creating a security group for the load balancer:
resource "aws_security_group" "footystats_web_alb_security_group" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0             # Allowing any incoming port
    to_port     = 0             # Allowing any outgoing port
    protocol    = "-1"          # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}

resource "aws_lb_target_group" "footystats_web_target_group" {
  name        = "footystats-web-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher  = "200,301,302"
    path     = "/"
    interval = 60
    timeout  = 30
  }
}

# Register a forwarding rule for HTTP from ALB to ECS through target group.
resource "aws_lb_listener" "footystats_web_http_listener" {
  load_balancer_arn = aws_alb.footystats_web_alb.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.footystats_web_target_group.arn # Referencing our target group
  }
}

# This data source looks up our Hosted Zone
data "aws_route53_zone" "aflfootystats_hosted_zone" {
  name         = "aflfootystats.com"
  private_zone = false
}

resource "aws_acm_certificate" "footystats_web_cert" {
  domain_name       = "*.aflfootystats.com"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Add a record pointing to our cert for TLS
resource "aws_route53_record" "footystats_web_cert_record" {
  zone_id = data.aws_route53_zone.aflfootystats_hosted_zone.zone_id
  name    = one(aws_acm_certificate.footystats_web_cert.domain_validation_options).resource_record_name
  records = [one(aws_acm_certificate.footystats_web_cert.domain_validation_options).resource_record_value]
  type    = one(aws_acm_certificate.footystats_web_cert.domain_validation_options).resource_record_type
  ttl     = 60
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.footystats_web_cert.arn
  validation_record_fqdns = [aws_route53_record.footystats_web_cert_record.fqdn]
}
