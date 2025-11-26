# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.project_name}-ec2-role-"

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

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# IAM Policy for EC2 instances (minimal permissions)
resource "aws_iam_role_policy" "ec2_policy" {
  name_prefix = "${var.project_name}-ec2-policy-"
  role        = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policy for SSM (Systems Manager) - enables secure shell access
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.project_name}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}

# User Data Script for EC2 instances
locals {
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))
}

# Bastion Host (Public Instance)
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public[0].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = local.user_data

  # Security best practices
  monitoring                          = var.enable_detailed_monitoring
  disable_api_termination            = false # Set to true in production
  instance_initiated_shutdown_behavior = "stop"

  # EBS optimization for better performance
  ebs_optimized = true

  # Root volume encryption
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-bastion-root-volume"
    }
  }

  # Metadata service configuration (IMDSv2 only)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "${var.project_name}-bastion-host"
    Role = "bastion"
    Tier = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Private Instances (4 instances in private subnets)
resource "aws_instance" "private" {
  count                  = var.vm_count - 1 # Subtract 1 because bastion counts as 1 VM
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.private_instances.id]
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = local.user_data

  # Security best practices
  monitoring                          = var.enable_detailed_monitoring
  disable_api_termination            = false # Set to true in production
  instance_initiated_shutdown_behavior = "stop"

  # EBS optimization for better performance
  ebs_optimized = true

  # Root volume encryption
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-private-${count.index + 1}-root-volume"
    }
  }

  # Metadata service configuration (IMDSv2 only)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name = "${var.project_name}-private-vm-${count.index + 1}"
    Role = "application"
    Tier = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for EC2 instances
resource "aws_cloudwatch_log_group" "ec2_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-ec2-logs"
  }
}