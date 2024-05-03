#!/bin/bash

# Check if AMI ID is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <AMI_ID>"
    exit 1
fi

AMI_ID=$1

# Function to fetch values from CF exports
fetch_cf_export() {
    local export_name=$1
    echo "Fetching value for $export_name..." >&2
    aws cloudformation list-exports \
        --query "Exports[?Name=='$export_name'].Value" \
        --output text
}

# Capture parameters from CloudFormation exports
SUBNET_ID=$(fetch_cf_export "PrivateSubnet2")
SECURITY_GROUP_ID=$(fetch_cf_export "PrivateSubnetSecurityGroup")

# Check for missing parameters
if [ -z "$SUBNET_ID" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    echo "Error: Missing required parameters from CloudFormation exports."
    echo "Subnet ID: $SUBNET_ID"
    echo "Security Group ID: $SECURITY_GROUP_ID"
    exit 1
fi

# Define the key pair name statically
KEY_PAIR_NAME="SeanKeyPair"

# Create EC2 instance
echo "Creating EC2 instance from AMI $AMI_ID..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "t2.micro" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --key-name "$KEY_PAIR_NAME" \
    --no-associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value='Instance-from-Docker-image'}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to create instance. Please check the provided parameters and try again."
    exit 1
fi

echo "Instance $INSTANCE_ID created successfully."
echo "Waiting for instance to be in 'running' state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
echo "Instance $INSTANCE_ID is now running."
