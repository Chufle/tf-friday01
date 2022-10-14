terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Create a VPC
resource "aws_vpc" "mainvpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "main VPC"
  }
}

# Public Subnet
resource "aws_subnet" "publicsubnet01" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet 01"
  }
}

# Private Subnet
resource "aws_subnet" "privatesubnet01" {
  vpc_id     = aws_vpc.mainvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private Subnet 01"
  }
}

resource "aws_internet_gateway" "igw01" {
  vpc_id = aws_vpc.mainvpc.id

  tags = {
    Name = "Internet GW 01"
  }
}

# public route table

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.mainvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw01.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "rt-assoc01" {
  subnet_id      = aws_subnet.publicsubnet01.id
  route_table_id = aws_route_table.publicrt.id
}


# Security Group

resource "aws_security_group" "basic" {
  name        = "basic sg"
  description = "Allow TLS HTTP SSH inbound traffic"
  vpc_id      = aws_vpc.mainvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls_https_ssh"
  }
}



####### EC2

resource "aws_instance" "instance01" {
  ami                         = "ami-08e2d37b6a0129927"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.publicsubnet01.id
  vpc_security_group_ids      = [aws_security_group.basic.id]
#  key_name                    = "mykey1"
  user_data = file("userdata.sh")
  tags = {
    Name = "Instance 01"
  }
}
