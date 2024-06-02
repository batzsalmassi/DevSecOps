# VPC Creation
resource "aws_vpc" "mainVPC" {
    cidr_block           = "${var.vpc_cidr_block}"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "mainVPC"
    }
}

# Calculate Subnet CIDR Blocks
locals {
  public_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr_block, 8, 2), # Divides the VPC CIDR into subnets /24 (8 additional bits)
    cidrsubnet(var.vpc_cidr_block, 8, 4)
  ]

  private_subnet_cidrs = [
    cidrsubnet(var.vpc_cidr_block, 8, 1),
    cidrsubnet(var.vpc_cidr_block, 8, 3)
  ]
}

# Public Subnet 1
resource "aws_subnet" "main-subnet-public-1" {
    vpc_id                  = aws_vpc.mainVPC.id
    cidr_block              = local.public_subnet_cidrs[0]
    map_public_ip_on_launch = true
    availability_zone       = "us-east-1a"
    tags = {
        Name = "main-Public-Subnet-1"
    }
}

# Private Subnet 1
resource "aws_subnet" "main-subnet-private-1" {
    vpc_id                  = aws_vpc.mainVPC.id
    cidr_block              = local.private_subnet_cidrs[0]
    map_public_ip_on_launch = false
    availability_zone       = "us-east-1a"
    tags = {
        Name = "main-Private-Subnet-1"
    }
}

# Public Subnet 2
resource "aws_subnet" "main-subnet-public-2" {
    vpc_id                  = aws_vpc.mainVPC.id
    cidr_block              = local.public_subnet_cidrs[1]
    map_public_ip_on_launch = true
    availability_zone       = "us-east-1b"
    tags = {
        Name = "main-Public-Subnet-2"
    }
}

# Private Subnet 2
resource "aws_subnet" "main-subnet-private-2" {
    vpc_id                  = aws_vpc.mainVPC.id
    cidr_block              = local.private_subnet_cidrs[1]
    map_public_ip_on_launch = false
    availability_zone       = "us-east-1b"
    tags = {
        Name = "main-Private-Subnet-2"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "main-igw" {
    vpc_id = aws_vpc.mainVPC.id
    tags = {
        Name = "main_igw"
    }
}

# Public Route Tables
resource "aws_route_table" "main-public-route" {
    vpc_id = aws_vpc.mainVPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main-igw.id
    }
    tags = {
        Name = "main-public-route"
    }
}

# Association for Public Subnet 1 to the Route Tables
resource "aws_route_table_association" "main-public-1-route-association" {
    subnet_id      = aws_subnet.main-subnet-public-1.id
    route_table_id = aws_route_table.main-public-route.id
}

# Association for Public Subnet 2 to the Route Tables
resource "aws_route_table_association" "main-public-2-route-association" {
    subnet_id      = aws_subnet.main-subnet-public-2.id
    route_table_id = aws_route_table.main-public-route.id
}

# Private Route Table
resource "aws_route_table" "main-private-route" {
    vpc_id = aws_vpc.mainVPC.id
    tags = {
        Name = "main-private-route"
    }
}

# Association for Private Subnet 1 to the Private Route Table
resource "aws_route_table_association" "main-private-1-route-association" {
    subnet_id      = aws_subnet.main-subnet-private-1.id
    route_table_id = aws_route_table.main-private-route.id
}

# Association for Private Subnet 2 to the Private Route Table
resource "aws_route_table_association" "main-private-2-route-association" {
    subnet_id      = aws_subnet.main-subnet-private-2.id
    route_table_id = aws_route_table.main-private-route.id
}

#Create a Public Security Group
resource "aws_security_group" "publicSG" {
    name = "publicSG"
    description = "Allow SSH,TCP,ICMP ports to 0.0.0.0/0 CIDR"
    vpc_id = aws_vpc.mainVPC.id

#Allowing SSH in port 22 to from and to the public
    ingress { 
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

#Allowing HTTP in port 80 to from and to the public
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

#Allowing ICMP in port all ports -1 to from and to the public
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "publicSG"
    }
}

#Create a Security Group for Instances in Private Subnet
resource "aws_security_group" "privateSG" {
    name = "privateSG"
    description = "Allow traffic between instances in the private subnet"
    vpc_id = aws_vpc.mainVPC.id

#Allowing SSH in port 22 to from and to the public
    ingress { 
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

#Allowing HTTP in port 80 to from and to the public
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

#Allowing ICMP in port all ports -1 to from and to the public
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#Create a VPC Endpoint gateway for s3
resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.mainVPC.id
    service_name = "com.amazonaws.${var.region}.s3"
    route_table_ids = [aws_route_table.main-private-route.id]
    vpc_endpoint_type = "Gateway"
    tags = {
        Name = "main-Private-S3-Endpoint-Gateway"
    }
}

#Create an EC2 Connect Endpoint
resource "aws_vpc_endpoint" "ec2" {
    vpc_id = aws_vpc.mainVPC.id
    service_name = "com.amazonaws.${var.region}.ec2"
    vpc_endpoint_type = "Interface"
    subnet_ids = [aws_subnet.main-subnet-private-2.id]
    security_group_ids = [aws_security_group.privateSG.id]
    tags = {
        Name = "main-ec2-connect-endpoint"
    }
}

# Outputs
output "vpc_id" {
  description = "Id of the VPC"
  value       = aws_vpc.mainVPC.id
}

output "public_subnet_1" {
  description = "Public Subnet 1"
  value       = aws_subnet.main-subnet-public-1.id
}

output "public_subnet_2" {
  description = "Public Subnet 2"
  value       = aws_subnet.main-subnet-public-2.id
}

output "private_subnet_1" {
  description = "Private Subnet 1"
  value       = aws_subnet.main-subnet-private-1.id
}

output "private_subnet_2" {
  description = "Private Subnet 2"
  value       = aws_subnet.main-subnet-private-2.id
}

output "public_security_group" {
  description = "Public Security Group"
  value       = aws_security_group.publicSG.id
}

output "private_security_group" {
  description = "Private Security Group"
  value       = aws_security_group.privateSG.id
}

output "availability_zone_1" {
  description = "Availability Zone 1"
  value       = aws_subnet.main-subnet-public-1.availability_zone
}

output "availability_zone_2" {
  description = "Availability Zone 2"
  value       = aws_subnet.main-subnet-public-2.availability_zone
}

output "s3_endpoint" {
  description = "S3 Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "ec2_connect_endpoint" {
  description = "Instance Connect Endpoint"
  value       = aws_vpc_endpoint.ec2.id
}