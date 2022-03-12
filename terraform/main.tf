provider "aws" {
    region = "var.region"
}

resource "aws_vpc" "javaapp-vpc"{
    cldr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "javaapp-subnet-1" {
  vpc_id     = aws_vpc.javaapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "main-rtb" {
  vpc_id     = aws_vpc.javaapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }

resource "aws_default_route_table" "prod-route-table" {
  default_route_table_id = aws_vpc.javaapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.javaapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-main-rtb"
  }
}

resource "aws_default_security_group" "default_sg" {
  vpc_id      = aws_vpc.javaapp-vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip, var.jenkins_ip]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["hvm"]
  }
}

resource "aws_instance" "javaapp-server" {
    ami = data.aws_ami.latest-amazon-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.javaapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.avail_zone
    
    associate_public_ip_address = true
    key_name = "javaapp-key-pair"

    user_data = file("entry-script")

    tag = {
        Name = "${var.env_prefix}-server"
    }
}

output "ec2_public_ip"{
  value = aws_instance.javaapp-server.public_ip
}