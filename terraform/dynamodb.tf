resource "aws_dynamodb_table" "analytics" {
  name         = "analytics_events"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}
