# Output values for the infrastructure
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "bastion_host_id" {
  description = "ID of the bastion host"
  value       = aws_instance.bastion.id
}

output "bastion_host_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_host_private_ip" {
  description = "Private IP address of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "private_instance_ids" {
  description = "IDs of the private instances"
  value       = aws_instance.private[*].id
}

output "private_instance_private_ips" {
  description = "Private IP addresses of the private instances"
  value       = aws_instance.private[*].private_ip
}

output "security_group_bastion_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion.id
}

output "security_group_private_id" {
  description = "ID of the private instances security group"
  value       = aws_security_group.private_instances.id
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of the NAT gateways"
  value       = aws_eip.nat[*].public_ip
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ec2_logs.name
}

# Connection information for SSH access
output "ssh_connection_command" {
  description = "SSH command to connect to bastion host (requires key pair)"
  value       = var.key_pair_name != null ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}" : "Key pair not specified - use AWS Systems Manager Session Manager instead"
}

output "ssm_connection_commands" {
  description = "AWS CLI commands to connect via Session Manager"
  value = {
    bastion = "aws ssm start-session --target ${aws_instance.bastion.id}"
    private_instances = [
      for instance in aws_instance.private :
      "aws ssm start-session --target ${instance.id}"
    ]
  }
}