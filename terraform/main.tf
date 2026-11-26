terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_key_pair" "dev_key" {
  key_name = "dev_key"
}

resource "aws_security_group" "frontend_sg" {
  name        = "v3-frontend-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name        = "v3-backend-sg"
  description = "Allow SSH, 8080 and 9090"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = "ami-07819de6092eaccdc"
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.dev_key.key_name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  tags = {
    Name = "v3-nginx-frontend"
  }
}

resource "aws_instance" "python" {
  ami                    = "ami-08915b9ee75b5bf00"
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.dev_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name = "v3-python-backend"
  }
}

resource "aws_instance" "java" {
  ami                    = "ami-08915b9ee75b5bf00"
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.dev_key.key_name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name = "v3-java-backend"
  }
}

output "nginx_ip" {
  value = aws_instance.nginx.public_ip
}

output "python_ip" {
  value = aws_instance.python.public_ip
}

output "java_ip" {
  value = aws_instance.java.public_ip
}