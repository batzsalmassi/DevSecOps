#!/bin/bash

#Variable for the bucket name
bucket_name="web-interface-bucket-test-sean-salmassi-v2"
# Upload files to S3
aws s3 cp /Users/sean.salmassi/github-Repos/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/resources/index.html s3://${bucket_name}/index.html
aws s3 cp /Users/sean.salmassi/github-Repos/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/resources/architecture-diagram.png s3://${bucket_name}/architecture-diagram.png
aws s3 cp /Users/sean.salmassi/github-Repos/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/resources/webpage2 s3://${bucket_name}/webpage2 --recursive

# Variables Stack #VPC
cf_s3_name="FinalProject-VPC"
cf_s3_template_path="/Users/sean.salmassi/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/Stack1-VPC"
# Deploy the VPC Cloudformation stack with default CIDR "10.0.0.0/16"
aws cloudformation deploy \
    --template-file ${cf_s3_template_path} \
    --stack-name ${cf_s3_name} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "Deployment triggered..."

# Variables Stack #EC2
bucket_name="web-interface-bucket-test-sean-salmassi-v2"
cf_ec2_name="FinalProject-EC2-ALB-ASG"
cf_ec2_template_path="/Users/sean.salmassi/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/Stack3-EC2-ALB-ASG"

# Deploy the EC2 CloudFormation stack
aws cloudformation deploy \
    --template-file ${cf_ec2_template_path} \
    --stack-name ${cf_ec2_name} \
    --parameter-overrides BucketName=${bucket_name} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "Deployment triggered..."

# Variables Stack #PrivateInstanceS3
cf_s3_name="FinalProject-S3"
cf_s3_template_path="/Users/sean.salmassi/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/Stack5-S3"

# Deploy the S3 Cloudformation Stack
aws cloudformation deploy \
    --template-file ${cf_s3_template_path} \
    --stack-name ${cf_s3_name} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "Deployment triggered..."

# Variables Stack #Budget
cf_s3_name="FinalProject-Budget"
cf_s3_template_path="/Users/sean.salmassi/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/Stack4-Budget"
# Deploy the S3 Cloudformation Stack
aws cloudformation deploy \
    --template-file ${cf_s3_template_path} \
    --stack-name ${cf_s3_name} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "Deployment triggered..."