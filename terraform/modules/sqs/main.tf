resource "aws_sqs_queue" "queues" {
  for_each = toset(var.queue_names)

  name                        = each.key
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  delay_seconds              = 0
  fifo_queue                 = false

  tags = {
    Project = "restaurant-recommendation"
    ManagedBy = "terraform"
  }
}
