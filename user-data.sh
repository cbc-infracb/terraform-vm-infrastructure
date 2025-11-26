#!/bin/bash

# User data script for EC2 instances
# This script runs on instance launch and sets up basic security and monitoring

# Update system packages
yum update -y

# Install essential packages
yum install -y \
    htop \
    curl \
    wget \
    unzip \
    amazon-cloudwatch-agent \
    awscli

# Configure automatic security updates
yum install -y yum-cron
systemctl enable yum-cron
systemctl start yum-cron

# Harden SSH configuration
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#Protocol 2/Protocol 2/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 300,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/${project_name}",
                        "log_stream_name": "{instance_id}/var/log/messages",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/secure",
                        "log_group_name": "/aws/ec2/${project_name}",
                        "log_stream_name": "{instance_id}/var/log/secure",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 300
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 300,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 300,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 300
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 300
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 300
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Enable and start CloudWatch agent service
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Create a banner file with system information
cat > /etc/motd << EOF
================================================================================
${project_name} - ${environment} Environment
================================================================================
This system is monitored and all activities are logged.
Unauthorized access is prohibited.

Instance Information:
- AMI: Amazon Linux 2
- Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)
- Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)
- Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

Security Features:
- IMDSv2 enforced
- EBS encryption enabled
- CloudWatch monitoring active
- Automatic security updates enabled
================================================================================
EOF

# Log the completion of user data script
echo "User data script completed at $(date)" >> /var/log/user-data.log