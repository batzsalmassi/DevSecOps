data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "sean-terraform-state-salmassi"
    key    = "terraform/tfstate"
    region = "us-east-1"
  }
}

###Create Load Balancer Resources
#Create Load Balancer Security Group
resource "aws_security_group" "LoadBalancer-SG" {
    name = "LoadBalancer-SG"
    description = "Security Group for the Load Balancer"
    vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

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
}



resource "aws_instance" "example" {
    ami =  lookup(var.amis, "${var.region}_${var.os}")
    instance_type = "t2.micro"
    subnet_id = data.terraform_remote_state.vpc.outputs.public_subnet_1
    tags = {
        Name = "${var.instanceName}_${var.os}_${var.region}"
    }
}
