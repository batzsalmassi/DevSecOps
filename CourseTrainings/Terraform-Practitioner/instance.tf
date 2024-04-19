resource "aws_instance" "example" {
    ami =  lookup(var.amis, "${var.region}_${var.os}")
    instance_type = "t2.micro"
    tags = {
        Name = "${var.instanceName}_${var.os}_${var.region}"
    }
}