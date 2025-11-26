# Security Group for Bastion Host (Public Access)
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-bastion-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for bastion host"

  # SSH access from allowed CIDR blocks only
  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidrs) > 0 ? var.allowed_ssh_cidrs : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH access from allowed networks"
    }
  }

  # Outbound internet access for updates and management
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Private Instances
resource "aws_security_group" "private_instances" {
  name_prefix = "${var.project_name}-private-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for private instances"

  # SSH access from bastion host only
  ingress {
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.bastion.id
    description              = "SSH access from bastion host"
  }

  # HTTP access within VPC (for internal communication)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTP access within VPC"
  }

  # HTTPS access within VPC (for internal communication)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access within VPC"
  }

  # Allow communication between private instances
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
    description = "Internal communication between private instances"
  }

  # Outbound internet access for updates and software installation
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-private-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group for Load Balancer (if needed in future)
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # HTTP access from internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access from internet"
  }

  # HTTPS access from internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access from internet"
  }

  # Outbound to private instances
  egress {
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.private_instances.id
    description              = "HTTP to private instances"
  }

  egress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.private_instances.id
    description              = "HTTPS to private instances"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}