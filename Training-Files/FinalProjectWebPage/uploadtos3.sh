#!/bin/bash

# Variables
bucket_name="web-interface-bucket-test-sean-salmassi"
cf_stack_name="FinalProject-EC2"
cf_template_path="/Users/sean.salmassi/DevSecOps/CourseTrainings/AWS-Practitioner/FinalProjectYamlStacks/Stack3-EC2"

# Upload files to S3
aws s3 cp /Users/sean.salmassi/DevSecOps/Training-Files/FinalProjectWebPage/index.html s3://${bucket_name}/index.html
aws s3 cp /Users/sean.salmassi/DevSecOps/Training-Files/FinalProjectWebPage/architecture-diagram.png s3://${bucket_name}/architecture-diagram.png

# Deploy the CloudFormation stack
aws cloudformation deploy \
    --template-file ${cf_template_path} \
    --stack-name ${cf_stack_name} \
    --parameter-overrides BucketName=${bucket_name} \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset

echo "Deployment triggered..."

