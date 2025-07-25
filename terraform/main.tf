terraform {
    required_version = ">= 0.12"
}

provider "aws" {
    region = "us-west-2"
}

variable "aws_id" {
    description = "AWS Account ID"
    type        = string
}

# fetch availability zones
# this 
data "aws_availability_zones" "available" {}  

# create a VPC & other networking resources
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0./16"
    tags = { Name = "echo-vpc"}
}

resource "aws_subnet" "public" {
    count = 2
    vpc_id            = aws_vpc.main.id
    cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

    availability_zone = data.aws_availability_zones.available.names[count.index]
    map_public_ip_on_launch = true
    tags = {
        Name = "echo-public-subnet-${count.index}"
    }

}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
    tags = {
        Name = "echo-public-route-table"
    }
}

resource "aws_route_table_association" "public" {
    count = length(aws_subnet.public)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

# dynamo db table
resource "aws_dynamodb_table" "time_string" {
    name         = "time_string"
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "string_name"
    range_key   = "timestamp"

    attribute {
        name = "string_name"
        type = "S"
    }
    attribute {
        name = "timestamp"
        type = "S"
    }
}

# security group for all ports to interact with our application

resource "aws_security_group" "ecs_tasks" {
    name        = "allow_all_tcp"
    description = "Allow inbound traffic from nlb"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# iam policy for code
data "aws_iam_policy_document" "ecs_task_policy" {
    statement {
        effect = "Allow"
        actions = [
            "sts:AsssumeRole"
        ]
        principals {
            type        = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

#dynamo db ecs task role
resource "aws_iam_role" "db_ecs_task_role" {
    name               = "db_ecs_task_role"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_policy.json
}  

resource "aws_iam_role_policy" "db_access_policy" {
    name = "db_access_policy"
    role = aws_iam_role.db_ecs_task_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect   = "Allow"
                Action   = [
                    "dynamodb:PutItem",
                    "dynamodb:Query",
                ]
                Resource = "aws_dynamodb_table.time_string.arn"
            }
        ]
    })
}

# ecs cluster
resource "aws_ecs_cluster" "main" {
    name = "echo-main-cluster"
}

# load balance
resource "aws_lb" "main" {
    name               = "main-lb"
    internal           = false
    load_balancer_type = "network"
    subnets            = aws_subnet.public[*].id   
}

module "app_service" {
  source = "../modules/app_service"

  for_each = {
    "echo-1337" = { port = 1337 }
    "echo-1338" = { port = 1338 }
    "echo-1440" = { port = 1440 }
  }

  name            = each.key
  port            = each.value.port
  image_uri       = "${var.aws_account_id}.dkr.ecr.us-east-1.amazonaws.com/${each.key}:latest"
  vpc_id          = aws_vpc.main.id
  subnets         = aws_subnet.public[*].id
  security_groups = [aws_security_group.ecs_tasks.id]
  ecs_cluster_id  = aws_ecs_cluster.main.id
  lb_arn          = aws_lb.main.arn

  task_role_arn = aws_iam_role.ecs_task_dynamodb_role.arn
  table_name    = aws_dynamodb_table.query_log.name
}