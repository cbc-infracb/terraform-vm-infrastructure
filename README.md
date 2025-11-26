# VM Infrastructure with Terraform

This Terraform configuration creates a secure, scalable infrastructure with 5 virtual machines on AWS following security best practices.

## Architecture Overview

- **1 Bastion Host** in a public subnet for secure access
- **4 Private Instances** in private subnets for applications
- **VPC** with public and private subnets across multiple AZs
- **NAT Gateways** for outbound internet access from private subnets
- **Security Groups** with least-privilege access controls
- **IAM Roles** with minimal required permissions
- **CloudWatch Logging** and monitoring

## Security Features

### Infrastructure Security
- ✅ All EC2 instances use encrypted EBS volumes
- ✅ IMDSv2 enforced (Instance Metadata Service v2)
- ✅ Security groups follow least-privilege principle
- ✅ Private instances isolated from direct internet access
- ✅ SSH access only through bastion host or AWS SSM
- ✅ NAT Gateways for secure outbound connectivity

### Access Control
- ✅ IAM roles with minimal permissions
- ✅ AWS Systems Manager (SSM) enabled for secure shell access
- ✅ SSH hardening via user data script
- ✅ Password authentication disabled

### Monitoring & Compliance
- ✅ CloudWatch agent installed and configured
- ✅ System logs centralized in CloudWatch
- ✅ Detailed monitoring enabled
- ✅ Automatic security updates configured

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (version >= 1.0)
3. **AWS credentials** set up via:
   - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
   - AWS CLI profile
   - IAM role (if running on EC2)

### Required AWS Permissions

Your AWS user/role needs permissions for:
- EC2 (instances, VPC, security groups, subnets, internet gateways, NAT gateways)
- IAM (roles, policies, instance profiles)
- CloudWatch (log groups, metrics)

## Quick Start

1. **Clone and navigate to the directory**
2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars with your values:**
   ```bash
   # IMPORTANT: Update allowed_ssh_cidrs with your IP address
   allowed_ssh_cidrs = ["YOUR_IP_ADDRESS/32"]

   # Optional: Specify existing key pair for SSH access
   key_pair_name = "your-existing-key-pair"
   ```

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Plan the deployment:**
   ```bash
   terraform plan
   ```

6. **Apply the configuration:**
   ```bash
   terraform apply
   ```

## Accessing Your VMs

### Option 1: SSH via Bastion Host (requires key pair)
```bash
# Connect to bastion host
ssh -i ~/.ssh/your-key.pem ec2-user@BASTION_PUBLIC_IP

# From bastion, connect to private instances
ssh ec2-user@PRIVATE_INSTANCE_IP
```

### Option 2: AWS Systems Manager Session Manager (recommended)
```bash
# Connect to bastion host
aws ssm start-session --target BASTION_INSTANCE_ID

# Connect to private instances
aws ssm start-session --target PRIVATE_INSTANCE_ID
```

## Configuration Options

### Variables You Can Customize

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `project_name` | Project name for resource naming | `vm-infrastructure` |
| `environment` | Environment (dev/staging/prod) | `dev` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `vm_count` | Number of VMs (1-10) | `5` |
| `allowed_ssh_cidrs` | CIDR blocks allowed SSH access | `[]` (must be set) |
| `key_pair_name` | AWS key pair name | `null` |

### Network Configuration
- VPC CIDR: `10.0.0.0/16`
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`
- Private subnets: `10.0.10.0/24`, `10.0.20.0/24`

## Monitoring and Logs

- **CloudWatch Agent** installed on all instances
- **System logs** sent to CloudWatch Logs: `/aws/ec2/{project-name}`
- **Metrics** collected: CPU, memory, disk, network
- **Log retention**: 30 days

## Security Best Practices Implemented

1. **Network Segmentation**: Private instances isolated from internet
2. **Least Privilege**: Minimal IAM permissions and security group rules
3. **Encryption**: EBS volumes encrypted at rest
4. **Access Control**: SSH hardening, no password authentication
5. **Monitoring**: Comprehensive logging and metrics
6. **Patch Management**: Automatic security updates enabled
7. **Metadata Security**: IMDSv2 enforced

## Cost Optimization

- Uses `t3.micro` instances (eligible for free tier)
- EBS GP3 volumes for cost-effective storage
- Can be easily scaled up/down by changing `vm_count`

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Production Considerations

Before using in production:

1. **Enable remote state** backend (S3 + DynamoDB)
2. **Set up proper RBAC** and access controls
3. **Configure backup strategies** for data
4. **Implement monitoring alerts**
5. **Set up CI/CD pipelines** for infrastructure changes
6. **Enable AWS Config** for compliance monitoring
7. **Consider using AWS WAF** if exposing web applications

## Troubleshooting

### Common Issues

1. **SSH Access Denied**
   - Ensure `allowed_ssh_cidrs` includes your IP address
   - Verify key pair is correctly specified and exists

2. **Instance Launch Fails**
   - Check AWS service limits
   - Verify AMI availability in your region

3. **Permission Errors**
   - Ensure AWS credentials have required permissions
   - Check IAM policy attachments

### Getting Help

- Check Terraform logs: `terraform apply -debug`
- Review AWS CloudTrail for API call logs
- Examine instance system logs in CloudWatch