# Karpenter IAM Role and Policies
# This creates the necessary IAM role and policies for Karpenter to manage EC2 instances

resource "aws_iam_role" "karpenter_controller" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_issuer}:sub" = "system:serviceaccount:karpenter:karpenter"
            "${var.oidc_issuer}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-karpenter-controller"
  })
}

# IAM policy for Karpenter controller
resource "aws_iam_policy" "karpenter_controller_policy" {
  name        = "${var.cluster_name}-karpenter-controller-policy"
  description = "IAM policy for Karpenter controller"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "iam:PassRole",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/karpenter.sh/cluster" = var.cluster_name
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

# Instance profile for Karpenter nodes
resource "aws_iam_role" "karpenter_node_instance_profile" {
  name = "${var.cluster_name}-karpenter-node-instance-profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-karpenter-node-instance-profile"
  })
}

# Attach required policies to the node instance profile
resource "aws_iam_role_policy_attachment" "karpenter_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

resource "aws_iam_role_policy_attachment" "karpenter_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

resource "aws_iam_role_policy_attachment" "karpenter_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node_instance_profile.name
}

# Create the instance profile
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = aws_iam_role.karpenter_node_instance_profile.name
  role = aws_iam_role.karpenter_node_instance_profile.name

  tags = var.common_tags
}

# SQS Queue for Karpenter interruption handling
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                      = "${var.cluster_name}-karpenter-interruption-queue"
  message_retention_seconds = 300

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-karpenter-interruption-queue"
  })
}

# EventBridge rules for EC2 interruption events
resource "aws_cloudwatch_event_rule" "karpenter_interruption_rule" {
  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Karpenter interruption handling"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["EC2 Spot Instance Interruption Warning", "EC2 Instance Rebalance Recommendation", "EC2 Instance State-change Notification"]
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "karpenter_interruption_queue_target" {
  rule      = aws_cloudwatch_event_rule.karpenter_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

# SQS queue policy to allow EventBridge to send messages
resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption_queue.arn
      }
    ]
  })
}
