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

resource "aws_instance" "jenkins" {
  ami = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  user_data = <<-EOL
#!/bin/bash
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt update && apt upgrade -y
apt install openjdk-11-jdk -y
apt install jenkins
cat /var/lib/jenkins/secrets/initialAdminPassword
  EOL
  
  tags = {
    Name = "jenkins"
  }
}

resource "aws_security_group" "jenkins" {
  name        = "all"
  description = "all"

  ingress {
      description      = "all"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
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
