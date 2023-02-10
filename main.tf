terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}

provider "aws" {
}

resource "aws_iam_role" "jenkins_server" {
  name = "jenkins-server"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess", "arn:aws:iam::aws:policy/AmazonEC2FullAccess","arn:aws:iam::aws:policy/AmazonS3BucketFullAccess"]


}

resource "aws_iam_instance_profile" "test_profile" {
  name = "jenkins-server"
  role = aws_iam_role.jenkins_server.name
}


resource "aws_instance" "jenkins_ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = ""
  vpc_security_group_ids = []
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  tags = {
    Name = var.tag
  }
  user_data = file("jenkins.sh")
}

resource "aws_security_group" "jenkins_security_group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}