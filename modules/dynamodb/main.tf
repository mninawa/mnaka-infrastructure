locals {
  dynamodb_table_attributes = flatten([{ "name": "id", "type": "S" }, var.CREATE_SORT_KEY ? [{ "name": "${var.SORT_KEY_NAME}", "type": "S" }] : []])
}

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "${var.ENV}-${var.RESOURCE_PREFIX}-table"
  billing_mode   = var.BILLING_MODE
  hash_key       = "id"
  range_key      = var.CREATE_SORT_KEY ? "${var.SORT_KEY_NAME}" : null
  
  dynamic "attribute" {
    for_each = local.dynamodb_table_attributes
    
    content {
      name = attribute.value["name"]
      type = attribute.value["type"]
    }
  }

  tags = var.COMMON_TAGS
}