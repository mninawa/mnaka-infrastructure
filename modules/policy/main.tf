################################################################################
# LAMBDA - DELETE EXPENSE TYPE
################################################################################

resource "aws_iam_policy" "ecs_service_policy" {
  name = "${var.RESOURCE_PREFIX}-ecs-service-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = "*",
        Resource = ["*"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_service_policy_attachment" {
  role       = "${var.ECS_SERVICE_ROLE_NAME}"
  policy_arn = "${aws_iam_policy.ecs_service_policy.arn}"
}