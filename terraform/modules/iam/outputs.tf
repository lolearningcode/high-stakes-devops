output "karpenter_controller_role_arn" {
  description = "ARN of the IAM role for Karpenter controller"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_instance_profile_name" {
  description = "Name of the instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_node_instance_profile.name
}

output "karpenter_interruption_queue_name" {
  description = "Name of the SQS queue for Karpenter interruption handling"
  value       = aws_sqs_queue.karpenter_interruption_queue.name
}
