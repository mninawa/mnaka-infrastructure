resource "aws_sns_topic" "ecr_scanner_topic" {
  name = "${var.RESOURCE_PREFIX}-ecr-scanner-topic"
}

resource "aws_sns_topic_subscription" "support_emails_subscription" {
  for_each = toset(var.SUPPORT_EMAILS)
  
  topic_arn = aws_sns_topic.ecr_scanner_topic.arn
  protocol  = "email"
  endpoint  = each.value
}