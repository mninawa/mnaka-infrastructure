output "ECS_SERVICE_ROLE_NAME" {
  value = aws_iam_role.ecs_service.name
}
output "ECS_SERVICE_ROLE_ARN" {
  value = aws_iam_role.ecs_service.arn
}