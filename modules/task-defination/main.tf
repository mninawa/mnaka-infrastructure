################################################################################
# ECS Service
################################################################################

module "container_definition" {
  source  = "./container-defination"
  container_name               = var.CONTAINER_NAME
  container_image              = var.CONTAINER_IMAGE
  container_memory             = 256
  container_memory_reservation = 128
  container_cpu                = 256
  essential                    = true
  readonly_root_filesystem     = false
  environment                  = var.CONTAINER_ENVIRONMENT
  port_mappings                = var.PORT_MAPPINGS
  log_configuration            = var.LOG_CONFIGURATION
}


resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.TASK_DEFINITION_FAMILY
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = module.container_definition.json_map_encoded_list
  execution_role_arn       = "arn:aws:iam::${var.CURRENT_ACCOUNT_ID}:role/ecsTaskExecutionRole"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  depends_on = [
    module.container_definition
  ]
}