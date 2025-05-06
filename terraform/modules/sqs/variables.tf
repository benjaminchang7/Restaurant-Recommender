variable "queue_names" {
  description = "List of SQS queue names to create"
  type        = list(string)
}

variable "region" {
  description = "AWS region to create the queues in"
  type        = string
}
