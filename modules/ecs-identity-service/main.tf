resource "aws_ecs_service" "service" {
  name = var.NAME

  cluster                            = var.ECS_CLUSTER_ARN
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 2
  enable_ecs_managed_tags            = false
  enable_execute_command             = false
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  force_new_deployment               = false

  load_balancer {
    target_group_arn = var.TARGET_GROUP_ARN
    container_name   = var.CONTAINER.NAME
    container_port   = var.CONTAINER.PORT
  }

  network_configuration {
    security_groups  = var.SECURITY_GROUPS
    subnets          = var.SUBNETS
    assign_public_ip = false
  }

  deployment_controller {
    type = "ECS"
  }

  platform_version = "1.4.0"
  propagate_tags   = "TASK_DEFINITION"
  task_definition = var.TASK_DEFINITION_ARN
  tags = var.COMMON_TAGS
}