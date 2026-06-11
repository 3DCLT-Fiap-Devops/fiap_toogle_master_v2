resource "aws_sqs_queue" "events" {
  name                      = "toogle-events"
  visibility_timeout_seconds = 30

  tags = {
    Project = var.project_name
  }
}
