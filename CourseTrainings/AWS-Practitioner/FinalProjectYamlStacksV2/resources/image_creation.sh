#!/bin/bash

# Export name of the EC2 Instance ID from CloudFormation
EXPORT_NAME_INSTANCE_ID="EC2PublicSubnet2"

# Fetch the EC2 Instance ID using the export name
INSTANCE_ID=$(aws cloudformation list-exports \
            --query "Exports[?Name=='$EXPORT_NAME_INSTANCE_ID'].Value" \
            --output text)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to retrieve EC2 Instance ID from CloudFormation exports." >&2
    exit 1
fi

echo "Using EC2 Instance ID: $INSTANCE_ID" >&2

# Define the name for the AMI
IMAGE_NAME="GoldenDockerAMI-$(date +%Y%m%d%H%M%S)"

# Stop the instance
echo "Stopping instance $INSTANCE_ID..." >&2
aws ec2 stop-instances --instance-ids "$INSTANCE_ID" >&2

# Wait for the instance to be in 'stopped' state
echo "Waiting for instance to be in 'stopped' state..." >&2
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID" >&2

# Create image from the stopped instance
echo "Creating image from instance $INSTANCE_ID..." >&2
image_id=$(aws ec2 create-image --instance-id "$INSTANCE_ID" --name "$IMAGE_NAME" --no-reboot --output text)

if [ -z "$image_id" ]; then
    echo "Failed to create image. Please check the instance ID and try again." >&2
    exit 1
fi

echo $image_id  # Only output the AMI ID to stdout
