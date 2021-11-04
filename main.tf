terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.63.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22, 8080]
}

resource "aws_instance" "jenkins" {
  ami = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name = "awsmykey"
  tags = {
    Name = "jenkins"
  }
}

provisioner "remote-exec" {
    inline = [
"sudo apt install ca-certificates",
"sudo wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add",
"sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'",
"sudo apt update && sudo apt upgrade -y",
"sudo apt install openjdk-11-jdk -y",
"sudo apt install jenkins -y"
    ]
  }

connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/awsmykey.pem")
  }

resource "aws_security_group" "jenkins" {
  name        = "http + ssh traffic"
  description = "http + ssh traffic"

  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "jenkins"
  }
}

output "instance_public_ip" {
  description = "IP address jenkins"
  value       = aws_instance.jenkins.public_ip
}