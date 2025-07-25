terraform {
    required_version = ">= 0.12"
}

required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
}

provider "aws" {
    region = "us-west-2"
}

variable "aws_id" {
    description = "AWS Account ID"
    type        = string
}

variable "domain_name" {
    description = "Domain name for the API Gateway"
    type        = string
}

# fetch availability zones
# this 
data "aws_availability_zones" "available" {
    state = "available"
}  

# create a VPC & other networking resources
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0./16"
}

resource "aws_subnet" "public" {
    count = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.${count.index + 1}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]
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

resource "aws_security_group" "api_sg" {
    name        = "allow_all_tcp"
    description = "Allow all inbound traffic"
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
resource "aws_iam_policy_document" "ecs_task_policy" {
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
    assume_role_policy = aws_iam_policy_document.ecs_task_policy.json
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
