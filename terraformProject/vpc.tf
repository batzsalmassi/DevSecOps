
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "moduleVPC"
  cidr = var.vpc_cidr_block

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  public_subnets  = [cidrsubnet(var.vpc_cidr_block, 8, 1), cidrsubnet(var.vpc_cidr_block, 8, 3)]
  private_subnets = [cidrsubnet(var.vpc_cidr_block, 8, 2), cidrsubnet(var.vpc_cidr_block, 8, 4)]

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_route_table" "private_rt" {
    vpc_id = module.vpc.vpc_id
    tags = {
        Name = "private-route-table"
    }
}

resource "aws_route_table_association" "private_rt_association_1" {
    subnet_id = module.vpc.private_subnets[0]
    route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_association_2" {
    subnet_id = module.vpc.private_subnets[1]
    route_table_id = aws_route_table.private_rt.id
}

