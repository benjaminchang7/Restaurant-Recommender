output "queue_arns" {
  description = "Map of queue names to their ARNs"
  value       = { for q in aws_sqs_queue.queues : q.name => q.arn }
}

output "queue_urls" {
  description = "Map of queue names to their URLs"
  value       = { for q in aws_sqs_queue.queues : q.name => q.url }
}
