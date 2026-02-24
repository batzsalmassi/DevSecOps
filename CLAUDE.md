# CLAUDE.md — DevSecOps Repository Guide

This file provides guidance for AI assistants (Claude and others) working with this repository. It describes the codebase structure, conventions, deployment workflows, and important context needed to contribute effectively.

---

## Repository Overview

This is an **educational DevSecOps training repository** owned by Sean Salmassi. It contains hands-on learning exercises and final projects for two cloud infrastructure courses:

1. **AWS Practitioner** — AWS CloudFormation-based infrastructure (VPC, EC2, IAM, S3, Lambda, ALB/ASG, Budgets)
2. **Terraform Practitioner** — Terraform-based infrastructure management on AWS

The repository demonstrates infrastructure-as-code (IaC) patterns, multi-tier VPC design, cloud automation with shell scripts, containerization, and serverless functions. It is **not** a production application — there are no application tests, CI/CD pipelines, or build systems.

---

## Directory Structure

```
DevSecOps/
├── CLAUDE.md                                  # This file
├── README.md                                  # Minimal project header
├── .gitignore                                 # Terraform-focused ignores
│
├── CourseTrainings/
│   ├── AWS-Practitioner/
│   │   ├── Lesson 2 - IAM/                    # IAM user/group CloudFormation templates
│   │   ├── Lesson 3 - VPC/                    # VPC homework templates
│   │   ├── Lesson 4 - Compute EC2/            # EC2 instance CloudFormation templates
│   │   ├── Lesson 6 - Lambda/                 # Lambda function templates
│   │   ├── FinalProjectYamlStacksV1/          # V1 CloudFormation final project
│   │   └── FinalProjectYamlStacksV2/          # V2 CloudFormation final project (current)
│   │       ├── Stack1-VPC                     # VPC, subnets, SGs, endpoints (YAML, no extension)
│   │       ├── Stack 2-IAM                    # IAM roles and policies
│   │       ├── Stack3-EC2-ALB-ASG             # EC2 + ALB + Auto Scaling Group
│   │       ├── Stack4-Budget                  # AWS Budgets alert
│   │       ├── Stack5-S3                      # S3 bucket
│   │       ├── VPC-with-NACL                  # VPC variant with Network ACLs
│   │       └── resources/
│   │           ├── automate-stack.sh          # Main deployment automation script
│   │           ├── csvTojson.py               # Lambda function: CSV → JSON converter
│   │           ├── Dockerfile                 # Apache httpd container image
│   │           ├── index.html                 # Static web page (architecture diagram)
│   │           ├── architecture-diagram.png   # Architecture diagram image
│   │           ├── image_creation.sh          # EC2 AMI creation script
│   │           ├── private_instance_from_image.sh  # Private EC2 from custom AMI
│   │           ├── commands.txt               # Reference AWS CLI commands
│   │           └── webpage2/                  # Secondary static web page with CSS
│   │
│   └── Terraform-Practitioner/
│       └── mainProject/                       # Primary Terraform project
│           ├── provider.tf                    # AWS provider configuration
│           ├── vpc.tf                         # VPC, subnets, route tables, SGs, endpoints
│           ├── instance.tf                    # EC2 instance + ALB security group
│           ├── var.tf                         # Variables (region, CIDR, OS, AMI map)
│           └── iam.tf                         # IAM placeholder (empty)
│
├── terraformProject/                          # Simple standalone Terraform VPC project
│   ├── provider.tf
│   ├── vpc.tf                                 # Uses terraform-aws-modules/vpc/aws module
│   ├── var.tf
│   └── security-group.tf                      # Placeholder (empty)
│
└── Training-Files/
    └── lambdaFunctionsFiles/
        └── csvTojson.py                       # Duplicate of the Lambda function above
```

---

## Technologies & AWS Services

### Infrastructure as Code
| Tool | Version | Usage |
|------|---------|-------|
| Terraform | AWS Provider 5.52.0 | VPC, subnets, SGs, endpoints, EC2, S3 remote state |
| AWS CloudFormation | YAML | VPC, IAM, EC2/ALB/ASG, S3, Budgets |

### AWS Services Used
- **VPC** — Multi-tier: 2 public subnets + 2 private subnets across 2 AZs
- **EC2** — Instances, AMIs, Auto Scaling Groups, Application Load Balancer
- **IAM** — Roles, policies, users, groups
- **S3** — Static website hosting, Terraform remote state backend
- **Lambda** — Serverless CSV-to-JSON converter (triggered by S3 events)
- **CloudWatch Budgets** — Cost alerting
- **VPC Endpoints** — S3 Gateway endpoint (private access), EC2 Instance Connect Endpoint
- **ECR (Amazon Linux base image)** — Used in Dockerfile

### Languages & Runtimes
- **HCL (Terraform)** — Infrastructure definitions
- **YAML / JSON** — CloudFormation templates (files have no `.yaml`/`.json` extension — they are raw YAML)
- **Python 3** (boto3) — Lambda function
- **Bash** — Deployment automation scripts
- **HTML/CSS** — Static web content
- **Docker** — Apache httpd container

---

## CloudFormation Conventions

### Template File Naming
CloudFormation templates in `FinalProjectYamlStacksV2/` have **no file extension** (e.g., `Stack1-VPC`, `Stack3-EC2-ALB-ASG`). They are YAML format. When referencing them with `aws cloudformation deploy --template-file`, use the path as-is.

### Stack Naming Pattern
```
FinalProject-<Component>
```
Examples: `FinalProject-VPC`, `FinalProject-EC2-ALB-ASG`, `FinalProject-S3`, `FinalProject-Budget`

### Cross-Stack References
Stacks communicate via CloudFormation **Exports/Imports**:
- Stack1-VPC exports: `VPCId`, `PublicSubnet1`, `PublicSubnet2`, `PrivateSubnet1`, `PrivateSubnet2`, `PublicSecurityGroup`, `PrivateSubnetSecurityGroup`, `AvailabilityZone1`, `AvailabilityZone2`, `S3GatewayEndpoint`, `EC2ConnectEndpoint`
- Downstream stacks (EC2, ALB) import these via `!ImportValue <ExportName>`

### Required Deploy Flags
Always include these when deploying stacks with IAM resources:
```bash
--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM
--no-fail-on-empty-changeset
```

### Deployment Order
Stacks must be deployed in dependency order:
1. `Stack1-VPC` (no dependencies)
2. `Stack 2-IAM` (no dependencies)
3. `Stack3-EC2-ALB-ASG` (depends on Stack1-VPC exports)
4. `Stack5-S3` (no stack dependencies)
5. `Stack4-Budget` (no stack dependencies)

---

## Terraform Conventions

### Project Structure
Each Terraform project follows this file layout:
- `provider.tf` — AWS provider + region
- `vpc.tf` — VPC infrastructure (subnets, IGW, route tables, SGs, VPC endpoints)
- `instance.tf` — EC2 resources (uses remote state data source for VPC outputs)
- `var.tf` — All variable declarations and defaults
- `iam.tf` — IAM resources (may be empty placeholder)

### Remote State
The `mainProject` reads VPC state from S3:
```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sean-terraform-state-salmassi"
    key    = "terraform/tfstate"
    region = "us-east-1"
  }
}
```
The VPC project must be applied first, and its state must be stored in this S3 bucket before applying `instance.tf`.

### Variable Passing
Variables without defaults must be provided at apply time via `-var` flags or a `terraform.tfvars` file (excluded from git — see `.gitignore`):
```bash
terraform apply \
  -var="region=us-east-1" \
  -var="vpc_cidr_block=10.0.0.0/16" \
  -var="instanceName=myInstance" \
  -var="os=AmazonLinux"
```

### AMI Map Convention
The `var.tf` in `mainProject` contains a map variable `amis` keyed by `"<region>_<OS>"`:
```hcl
lookup(var.amis, "${var.region}_${var.os}")
```
Supported OS values: `AmazonLinux`, `Ubuntu`, `Windows`
Supported regions: `us-east-1`, `ca-central-1`, `eu-central-1`

### Terraform Workflow
```bash
terraform init       # Initialize providers and modules
terraform plan       # Preview changes
terraform apply      # Apply infrastructure
terraform destroy    # Tear down infrastructure
```

### gitignore Rules (Terraform)
The following are excluded from version control:
- `.terraform/` directories
- `*.tfstate`, `*.tfstate.*`
- `*.tfvars`, `*.tfvars.json`
- `override.tf`, `*_override.tf`
- `backend.tf`
- `crash.log`
- `.terraformrc`, `terraform.rc`

**Never commit `.tfvars` files** — they may contain sensitive values (access keys, secrets).

---

## Deployment Workflows

### CloudFormation (Automated)
Use the provided script to deploy all stacks:
```bash
cd CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/resources/
./automate-stack.sh
```

**Note:** The script contains hardcoded local paths (`/Users/sean.salmassi/...`) and a hardcoded S3 bucket name (`web-interface-bucket-test-sean-salmassi-v2`). Update these paths for your environment before running.

### CloudFormation (Manual)
```bash
aws cloudformation deploy \
  --template-file <path-to-template> \
  --stack-name <stack-name> \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset
```

### Lambda Deployment
The Lambda function (`csvTojson.py`) is deployed via the CloudFormation template in `Stack3-EC2-ALB-ASG` or manually via AWS Console/CLI. It is triggered by S3 `ObjectCreated` events.

### Docker (Local Testing)
```bash
cd CourseTrainings/AWS-Practitioner/FinalProjectYamlStacksV2/resources/
docker build -t web-server .
docker run -p 80:80 web-server
```

### EC2 Image Scripts
```bash
# Create an AMI from a running EC2 instance
./image_creation.sh

# Launch a private EC2 instance from a custom AMI
./private_instance_from_image.sh
```

---

## Security Notes

These are **training/educational** configurations. The following patterns exist for learning purposes but should not be used in production:

- Security groups allow SSH (port 22) from `0.0.0.0/0` (all IPs) — restrict to known IPs in production
- Security groups allow ICMP from `0.0.0.0/0` — restrict as needed
- Shell scripts contain hardcoded S3 bucket names and file paths
- No secrets management (AWS Secrets Manager / Parameter Store) is used
- EC2 Instance Connect Endpoint is used instead of a bastion host for private instance access

---

## Key Patterns & Observations

### VPC Architecture
Both Terraform and CloudFormation projects implement the same multi-tier VPC pattern:
- **CIDR**: `10.0.0.0/16` (default)
- **Public subnets**: `10.0.2.0/24` (AZ-a), `10.0.4.0/24` (AZ-b) — internet-accessible
- **Private subnets**: `10.0.1.0/24` (AZ-a), `10.0.3.0/24` (AZ-b) — no internet route
- **Internet Gateway** attached to VPC, routed from public subnets
- **S3 Gateway Endpoint** on private route table (avoids internet for S3 traffic)
- **EC2 Instance Connect Endpoint** in private subnet (replaces bastion host)

### Tagging Convention
Resources use the `Name` tag consistently. In CloudFormation, `!Sub ${AWS::StackName}-<ResourceType>` is used to scope names to the stack.

### CIDR Calculation
CloudFormation uses `!Cidr` intrinsic function to dynamically calculate subnet CIDRs from the VPC CIDR parameter. Terraform uses the `cidrsubnet()` function.

### Python Lambda
The `csvTojson.py` function:
- Triggered by S3 `ObjectCreated` events
- Reads CSV from the triggering S3 bucket/key
- Writes a `.json` file with the same name to the same bucket
- Handles URL-encoded S3 key names
- Returns 200 for non-CSV files (no-op)

---

## Git Workflow

- **Main branch**: `master`
- **Feature branches**: Follow pattern `<username>/<description>` or `claude/<description>`
- Commits are made directly; PRs are merged into master
- State files (`.tfstate`) must never be committed (enforced by `.gitignore`)

---

## AWS Region

The primary region used throughout this project is **`us-east-1`** (N. Virginia). Some AMI mappings also include `ca-central-1` and `eu-central-1`.
