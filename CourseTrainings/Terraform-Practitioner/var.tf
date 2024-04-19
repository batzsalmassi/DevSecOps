variable "aws_ACCESS_KEY" {}
variable "aws_SECRET_KEY" {}
variable "instanceName" {
    type = string
    description = "The name of the instance"
}


variable "region" {
    type = string
    description = "The region for the instance"
}

variable "os" {
    type = string
    description = "The Available OS to choose are: AmazonLinux, Ubuntu, Windows"
}

variable "amis" {
    description = "Mapping of AMIs based on region and OS"
    type = map(string)
    default = {
        "us-east-1_AmazonLinux" = "ami-051f8a213df8bc089"
        "us-east-1_Ubuntu" = "ami-080e1f13689e07408"
        "us-east-1_Windows" = "ami-03cd80cfebcbb4481"
        "ca-central-1_AmazonLinux" = "ami-07413789aae50b0e0"
        "ca-central-1_Ubuntu" = "ami-085c5194d6f95060c"
        "ca-central-1_Windows" = "ami-085c5194d6f95060c"
        "eu-central-1_AmazonLinux" = "ami-0f7204385566b32d0"
        "eu-central-1_Ubuntu" = "ami-0f673487d7e5f89ca"
        "eu-central-1_Windows" = "ami-0e9ea35223a924666"
    }

}
