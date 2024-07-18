resource "aws_sqs_queue" "events_queue" {
  name                      = "${var.RESOURCE_PREFIX}-queue"
  delay_seconds             = 10
  max_message_size          = 262144 #256 KiB
  message_retention_seconds = 3600
  visibility_timeout_seconds = 900
  receive_wait_time_seconds = 10

  tags = var.COMMON_TAGS
}