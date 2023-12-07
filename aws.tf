# AWS 서비스 및 지역 설정 (서울 지역)
provider "aws" {
    region = "ap-northeast-2"
}

# EC2 인스턴스 생성
resource "aws_instance" "AWS-my-EC2" {
    ami           = "ami-01123b84e2a4fba05"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.AWS-my-subnet-A.id

    tags = {
        Name = "AWS-my-EC2"
    }

    # 보안 그룹 설정
    vpc_security_group_ids = [aws_security_group.AWS-my-sg.id]
}

# 보안 그룹 생성
resource "aws_security_group" "AWS-my-sg" {
    name        = "AWS-my-sg"
    description = "Security group for my EC2 instance"
    vpc_id      = aws_vpc.AWS-my-vpc.id

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
        from_port   = 443
        to_port     = 443
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

# VPC 리소스 생성
resource "aws_vpc" "AWS-my-vpc" {
    cidr_block = "172.16.0.0/16"
    tags = {
        Name = "AWS-my-vpc"
    }
}

# Subnet 리소스 생성
resource "aws_subnet" "AWS-my-subnet-A" {
    vpc_id            = aws_vpc.AWS-my-vpc.id
    cidr_block        = "172.16.10.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "AWS-my-subnet-A"
    }
}

resource "aws_subnet" "AWS-my-subnet-B" {
    vpc_id            = aws_vpc.AWS-my-vpc.id
    cidr_block        = "172.16.20.0/24"
    availability_zone = "ap-northeast-2c"
    tags = {
        Name = "AWS-my-subnet-B"
    }
}

# 오토스케일링에 사용될 Launch Configuration 생성
resource "aws_launch_configuration" "AWS-my-AS-config" {
    name                 = "myLaunchConfig"
    image_id             = "ami-01123b84e2a4fba05"
    instance_type        = "t2.micro"
    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
}

# 오토스케일링 그룹 생성
resource "aws_autoscaling_group" "AWS-my-AS" {
    desired_capacity     = 2
    max_size             = 3
    min_size             = 1
    vpc_zone_identifier = [aws_subnet.AWS-my-subnet-A.id, aws_subnet.AWS-my-subnet-B.id]
    launch_configuration = aws_launch_configuration.AWS-my-AS-config.id

    tag {
        key                 = "Name"
        value               = "AWS-my-AS"
        propagate_at_launch = true
    }
}
