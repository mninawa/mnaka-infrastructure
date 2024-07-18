locals {
  RESOURCE_PREFIX = "${lower(var.ENV)}"
  VPC_NAME = "${local.RESOURCE_PREFIX}-vpc"
  CONTAINER = {
    IDENTITY = {
      NAME = "${local.RESOURCE_PREFIX}-identity-api-image"
      IMAGE = "079486612340.dkr.ecr.af-south-1.amazonaws.com/umnaka.identity:latest"
      PORT = 8000
    }
    POLICY = {
      NAME = "${local.RESOURCE_PREFIX}-policy-api-image"
      IMAGE = "079486612340.dkr.ecr.af-south-1.amazonaws.com/umnaka.policy:latest"
      PORT = 8100
    }
  }
}


################################################################################
# Roles
################################################################################
module "role" {
  source = "./modules/role"
  RESOURCE_PREFIX = local.RESOURCE_PREFIX

}

################################################################################
# Policies
################################################################################
module "policies" {
  source = "./modules/policy"
  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  AWS_REGION = var.REGION
  CURRENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id

  ECS_SERVICE_ROLE_NAME = module.role.ECS_SERVICE_ROLE_NAME
}



################################################################################
# VPC
################################################################################
module "vpc" {
  source = "./modules/vpc"

  name = local.VPC_NAME
  cidr = var.VPC["CIDR"]

  azs = ["${var.REGION}a", "${var.REGION}b"]
  private_subnets = var.VPC["SUBNET_PRIVATE"]
  public_subnets  = var.VPC["SUBNET_PUBLIC"]
  database_subnets = var.VPC["SUBNET_DB"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.common_tags
}


resource "aws_security_group" "sg_vpc" {
  name        = "${local.RESOURCE_PREFIX}-allow-TLS"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "SQL access from within VPC"
    from_port        = 1433
    to_port          = 1433
    protocol         = "tcp"
    cidr_blocks      = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = local.RESOURCE_PREFIX
  }

  depends_on = [
    module.vpc
  ]
}




################################################################################
# Load Balancer
################################################################################
module "alb" {
  source = "./modules/alb"
  
  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  VPC_ID  = module.vpc.vpc_id
  DEFAULT_SECURITY_GROUP_ID = module.vpc.default_security_group_id
  PUBLIC_SUBNETS = module.vpc.public_subnets
  PORTS = [
    local.CONTAINER.AVS.PORT,
    local.CONTAINER.CURRENCY_CONVERSION.PORT,
    local.CONTAINER.FRONT_END.PORT
  ]

  depends_on = [
    module.vpc
  ]
}



################################################################################
# Cloudwatch LogGroup(s)
################################################################################
resource "aws_cloudwatch_log_group" "identity_log_group" {
  name = "${local.RESOURCE_PREFIX}/mnaka-dev/identity-api"

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "policy_log_group" {
  name = "${local.RESOURCE_PREFIX}/mnaka-dev/policy-api"

  tags = local.common_tags
}



################################################################################
# ECS Cluster
################################################################################
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${local.RESOURCE_PREFIX}-cluster"
  tags = local.common_tags
}



################################################################################
# Task Defination(s)
################################################################################
module "identity_task_definition" {
  source = "./modules/task-defination"

  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  CONTAINER_NAME = local.CONTAINER.IDENTITY.NAME
  CONTAINER_IMAGE = local.CONTAINER.IDENTITY.IMAGE
  CONTAINER_ENVIRONMENT = [
    {
      name  = "string_var"
      value = "I am a string"
    }
  ]
  PORT_MAPPINGS = [
    {
      containerPort = local.CONTAINER.IDENTITY.PORT
      hostPort      = 8000
      protocol      = "tcp"
    }
  ]

  LOG_CONFIGURATION = {
    logDriver = "awslogs"
    options = {
      "awslogs-group" = "${aws_cloudwatch_log_group.identity_log_group.name}"
      "awslogs-region" = "${var.REGION}"
      "awslogs-stream-prefix" = "mnaka-dev"
    }
    secretOptions = null
  }
  TASK_DEFINITION_FAMILY = "${local.RESOURCE_PREFIX}-identity-api-td"
  CURRENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id
}

module "policy_task_definition" {
  source = "./modules/task-defination"

  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  CONTAINER_NAME = local.CONTAINER.POLICY.NAME
  CONTAINER_IMAGE = local.CONTAINER.POLICY.IMAGE
  CONTAINER_ENVIRONMENT = [
    {
      name  = "string_var"
      value = "I am a string"
    }
  ]
  PORT_MAPPINGS = [
    {
      containerPort = local.CONTAINER.POLICY.PORT
      hostPort      = 8100
      protocol      = "tcp"
    }
  ]

  LOG_CONFIGURATION = {
    logDriver = "awslogs"
    options = {
      "awslogs-group" = "${aws_cloudwatch_log_group.policy_log_group.name}"
      "awslogs-region" = "${var.REGION}"
      "awslogs-stream-prefix" = "ecs"
    }
    secretOptions = null
  }
  TASK_DEFINITION_FAMILY = "${local.RESOURCE_PREFIX}-policy-api-td"
  CURRENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id
}


################################################################################
# ECS Service(s)
################################################################################
module "ecs_identity_service" {
  source              = "./modules/ecs-identity-service"
  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  NAME = "${local.RESOURCE_PREFIX}-identity-service"
  COMMON_TAGS = local.common_tags

  ECS_CLUSTER_ARN = aws_ecs_cluster.ecs_cluster.arn
  CONTAINER  = local.CONTAINER.AVS
  SECURITY_GROUPS = [module.vpc.default_security_group_id]
  SUBNETS = module.vpc.private_subnets
  TASK_DEFINITION_ARN = module.identity_task_definition.ARN
  TARGET_GROUP_ARN = module.alb.ARN

  depends_on      = [
    aws_ecs_cluster.ecs_cluster,
    module.vpc,
    module.identity_task_definition,
    module.alb
  ]
}

module "ecs_policy_service" {
  source              = "./modules/ecs-policy-service"
  RESOURCE_PREFIX = local.RESOURCE_PREFIX
  NAME = "${local.RESOURCE_PREFIX}-policy-service"
  COMMON_TAGS = local.common_tags

  ECS_CLUSTER_ARN = aws_ecs_cluster.ecs_cluster.arn
  CONTAINER  = local.CONTAINER.POLICY
  SECURITY_GROUPS = [module.vpc.default_security_group_id]
  SUBNETS = module.vpc.private_subnets
  TASK_DEFINITION_ARN = module.policy_task_definition.ARN
  TARGET_GROUP_ARN = module.alb.ARN

  depends_on      = [
    aws_ecs_cluster.ecs_cluster,
    module.vpc,
    module.policy_task_definition,
    module.alb
  ]
}


################################################################################
# DynamoDB
################################################################################
module "event_logging_dynamodb" {
  source = "./modules/dynamodb"
  ENV = var.ENV
  RESOURCE_PREFIX = "event-logging"
  CREATE_SORT_KEY = false
  COMMON_TAGS = local.common_tags
}