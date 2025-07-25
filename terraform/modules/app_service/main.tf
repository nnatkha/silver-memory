variable "name" {}
variable "port" {}
variable "image_uri" {}
variable "vpc_id" {}
variable "subnets" {}
variable "security_groups" {}
variable "ecs_cluster_id" {}
variable "lb_arn" {}
variable "task_role_arn" { default = null }
variable "table_name" {}

resource "aws_lb_target_group" "app" {
  name     = "${var.name}-tg"
  port     = var.port
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = var.lb_arn
  port              = var.port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = var.task_role_arn
  execution_role_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"


  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image_uri
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{ containerPort = var.port, hostPort = var.port }]
    environment = [
      { name  = "DYNAMODB_TABLE", value = var.table_name },
      { name  = "SERVICE_NAME",    value = var.name }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/my-project/${var.name}",
        "awslogs-region"        = "us-west-2",
        "awslogs-stream-prefix" = "ecs",
        "awslogs-create-group" = "true"
      }
    }
  }])
}

data "aws_region" "current" {}

resource "aws_ecs_service" "app" {
  name            = "${var.name}-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count  = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnets
    security_groups = var.security_groups
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.name
    container_port   = var.port
  }

  depends_on = [ aws_lb_listener.app ]
}

output "load_balancer_dns_name" {
  value = var.lb_arn != "" ? element(split("/", var.lb_arn), 1) : ""

}