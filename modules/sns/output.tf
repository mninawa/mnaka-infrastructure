output "SUPPORT_EMAIL_SNS_TOPIC_ARN" {
  value = "${aws_sns_topic.ecr_scanner_topic.arn}"
}