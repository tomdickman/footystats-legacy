terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"

  backend "s3" {
    bucket         = "footystats-terraform-state" // Pre-existing bucket to store tfstate
    key            = "terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "footystats-terraform" // Pre-existing Dynamo DB for state locking https://www.terraform.io/language/state/locking
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# Repo for storing Web App images
data "aws_ecr_repository" "footystats_web_ecr_repo" {
  name = "footystats_web_ecr_repo"
}

# Repo for storing Lambda API images
data "aws_ecr_repository" "footystats_api_ecr_repo" {
  name = "footystats_api_ecr_repo"
}

resource "aws_ecs_cluster" "footystats_cluster" {
  name = "footystats_cluster"
}

resource "aws_ecs_task_definition" "footystats_web_task" {
  family = "footystats_web_task"
  container_definitions = jsonencode([
    {
      "name" : "footystats_web_task",
      "image" : "${data.aws_ecr_repository.footystats_web_ecr_repo.repository_url}",
      "environment": [
        {
          "name": "API_URL",
          "value": format(
            "%s%s/%s",
            aws_api_gateway_deployment.footystats_api_deployment.invoke_url,
            aws_api_gateway_stage.footystats_api_prod.stage_name,
            aws_api_gateway_resource.graphql.path_part
          )
        }
      ]
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
    from_port   = 443 # Allowing traffic in from port 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

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

# Register a forwarding rule for HTTPS from ALB to ECS through target group.
resource "aws_lb_listener" "footystats_web_https_listener" {
  load_balancer_arn = aws_alb.footystats_web_alb.arn # Referencing our load balancer
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # The default policy
  certificate_arn   = aws_acm_certificate.footystats_web_cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.footystats_web_target_group.arn # Referencing our target group
  }
}


# Register a forwarding rule for HTTP from ALB to ECS through target group.
resource "aws_lb_listener" "footystats_web_http_listener" {
  load_balancer_arn = aws_alb.footystats_web_alb.arn # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      query       = "#{query}"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# This data source looks up our Hosted Zone
data "aws_route53_zone" "aflfootystats_hosted_zone" {
  name         = "aflfootystats.com"
  private_zone = false
}

resource "aws_acm_certificate" "footystats_web_cert" {
  domain_name               = "www.aflfootystats.com"
  validation_method         = "DNS"
  subject_alternative_names = ["aflfootystats.com"]
  lifecycle {
    create_before_destroy = true
  }
}

# Add a record pointing to our cert for TLS
resource "aws_route53_record" "footystats_web_cert_record" {
  zone_id         = data.aws_route53_zone.aflfootystats_hosted_zone.zone_id
  allow_overwrite = true

  for_each = {
    for dvo in aws_acm_certificate.footystats_web_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
}

# This tells terraform to cause the route53 validation to happen
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.footystats_web_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.footystats_web_cert_record : record.fqdn]
}

# Redirect all traffic to the ALB
resource "aws_route53_record" "footystats_web_record" {
  zone_id = data.aws_route53_zone.aflfootystats_hosted_zone.zone_id
  name    = data.aws_route53_zone.aflfootystats_hosted_zone.name
  type    = "A"
  alias {
    name                   = aws_alb.footystats_web_alb.dns_name
    zone_id                = aws_alb.footystats_web_alb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_iam_role" "footystats_api_function_role" {
  name = "footystats_api_function_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# The Apollo Server lambda function
resource "aws_lambda_function" "footystats_api_function" {
  function_name = "footystats_api_function"
  role          = aws_iam_role.footystats_api_function_role.arn
  image_uri     = "${data.aws_ecr_repository.footystats_api_ecr_repo.repository_url}:latest"
  package_type  = "Image"
  environment {
    variables = {
      PGDATABASE = var.pg_database,
      PGHOST = var.pg_host,
      PGPASSWORD = var.pg_password,
      PGPORT = var.pg_port,
      PGUSER = var.pg_user
    }
  }
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
resource "aws_cloudwatch_log_group" "footystats_api_function" {
  name              = "/aws/lambda/footystats_api_function"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "footystats_api_lambda_logging_policy" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.footystats_api_function_role.name
  policy_arn = aws_iam_policy.footystats_api_lambda_logging_policy.arn
}

# The REST API for handling GraphQL queries
resource "aws_api_gateway_rest_api" "footystats_api" {
  name = "footystats_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# /graphql resource for conducting GraphQL queries
resource "aws_api_gateway_resource" "graphql" {
  rest_api_id = aws_api_gateway_rest_api.footystats_api.id
  parent_id = aws_api_gateway_rest_api.footystats_api.root_resource_id
  path_part = "graphql"
}

# POST method attached to /graphql resource
resource "aws_api_gateway_method" "post" {
  rest_api_id = aws_api_gateway_rest_api.footystats_api.id
  resource_id = aws_api_gateway_resource.graphql.id
  http_method = "POST"
  authorization = "None"
  api_key_required = false

}

# Integration to proxy REST API /graphql endpoint to invoke Apollo Server Lambda
resource "aws_api_gateway_integration" "footystats_api_integration" {
  rest_api_id = aws_api_gateway_rest_api.footystats_api.id
  resource_id = aws_api_gateway_resource.graphql.id
  http_method = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.footystats_api_function.invoke_arn
}

# Deployment of REST API
resource "aws_api_gateway_deployment" "footystats_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.footystats_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.graphql.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.footystats_api_integration.id
    ]))
  }
  depends_on = [
    aws_api_gateway_integration.footystats_api_integration
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Production deployment of API
resource "aws_api_gateway_stage" "footystats_api_prod" {
  deployment_id = aws_api_gateway_deployment.footystats_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.footystats_api.id
  stage_name    = "prod"
}

# Allows any stage of the REST API to invoke the lambda through the POST method on the /graphql resource
resource "aws_lambda_permission" "footystats_lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.footystats_api_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # The `*` denotes a wildcard for the stage part or ARN, so this permission covers all stages.
  source_arn = "${aws_api_gateway_rest_api.footystats_api.execution_arn}/*/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.graphql.path}"
}
