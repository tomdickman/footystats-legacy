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
  region  = "ap-southeast-2"
}

resource "aws_ecr_repository" "footystats_web_ecr_repo" {
  name           = "footystats_web_ecr_repo"
}

resource "aws_ecs_cluster" "footystats_cluster" {
  name = "footystats_cluster"
}

resource "aws_ecs_task_definition" "footystats_web_task" {
  family                   = "footystats_web_task"
  container_definitions    = jsonencode([
    {
      "name": "footystats_web_task",
      "image": "${aws_ecr_repository.footystats_web_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ])
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_ecs_service" "footystats_web_service" {
  name            = "footystats_web_service"                             # Naming our service
  cluster         = "${aws_ecs_cluster.footystats_cluster.id}"           # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.footystats_web_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 1 # Setting the number of containers we want deployed

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
    assign_public_ip = true # Providing our containers with public IPs
  }
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
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
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
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
