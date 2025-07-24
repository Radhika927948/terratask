provider "aws" {
  region = "us-east-1"  # Change as needed
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "MainIGW"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a" # Adjust zones or use a list for variety

  tags = {
    Name = "PublicSubnet${count.index + 1}"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 3)
  map_public_ip_on_launch = false
  availability_zone = "us-east-1b"

  tags = {
    Name = "PrivateSubnet${count.index + 1}"
  }
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "WebAccessSG"
  description = "Allow ports 22, 80, and 8080"
  vpc_id      = aws_vpc.main.id

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

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebAccessSG"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c94855ba95c71c99" # Ubuntu Server 20.04 LTS in us-east-1, update per region
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public[0].id
  security_groups = [aws_security_group.web_sg.name]
  key_name      = "linux" # Replace with your actual key pair name

  tags = {
    Name = "UbuntuInstance"
  }
}

