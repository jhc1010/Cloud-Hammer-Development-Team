# AWS, region : seoul
provider "aws" {
    access_key = jsondecode(file("aws.json")).aws_credentials.access_key_id
    secret_key = jsondecode(file("aws.json")).aws_credentials.secret_access_key
    region = "ap-northeast-2"
}

# VPC 리소스 생성
resource "aws_vpc" "AWS-VPC" {
    cidr_block = "172.16.0.0/16"
    tags = {
        Name = "AWS-VPC"
    }
}

# Subnet 리소스 생성
resource "aws_subnet" "AWS-Subnet" {
    vpc_id            = aws_vpc.AWS-VPC.id
    cidr_block        = "172.16.10.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "AWS-Subnet"
    }
}


# 보안 그룹 생성
resource "aws_security_group" "AWS-SecurityGroup" {
    name        = "AWS-SecurityGroup"
    description = "Security group for my EC2 instance"
    vpc_id      = aws_vpc.AWS-VPC.id

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

# EC2 인스턴스 생성
resource "aws_instance" "AWS-Server" {
    ami           = "ami-01123b84e2a4fba05"
    instance_type = "t2.micro"
    subnet_id     = aws_subnet.AWS-Subnet.id

    tags = {
        Name = "AWS-Server"
    }

    # 보안 그룹 설정
    vpc_security_group_ids = [aws_security_group.AWS-SecurityGroup.id]
}

# 오토스케일링에 사용될 Launch Configuration 생성
resource "aws_launch_configuration" "AWS-AS-config" {
    name                 = "myLaunchConfig"
    image_id             = "ami-01123b84e2a4fba05"
    instance_type        = "t2.micro"
    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
}

# 오토스케일링 그룹 생성
resource "aws_autoscaling_group" "AWS-AutoScaling" {
    desired_capacity     = 2
    max_size             = 3
    min_size             = 1
    vpc_zone_identifier = [aws_subnet.AWS-Subnet.id]
    launch_configuration = aws_launch_configuration.AWS-AS-config.id

    tag {
        key                 = "Name"
        value               = "AWS-AutoScaling"
        propagate_at_launch = true
    }
}