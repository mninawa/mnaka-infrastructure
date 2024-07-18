################################################################################
# ECS - Service
################################################################################

resource "aws_iam_role" "ecs_service" {
  name = "${var.RESOURCE_PREFIX}-ecs-service-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : ["ecs.amazonaws.com"]
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}