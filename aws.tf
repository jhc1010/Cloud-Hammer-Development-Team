# AWS 서비스 및 지역 설정 (서울 지역)
provider "aws" {
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

/* resource "aws_subnet" "AWS-Subnet-B" {
    vpc_id            = aws_vpc.AWS-VPC.id
    cidr_block        = "172.16.20.0/24"
    availability_zone = "ap-northeast-2c"
    tags = {
        Name = "AWS-Subnet-B"
    }
} */

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





/* # AWS 서비스 및 지역 설정 (오하이오 지역)
provider "aws" {
    alias  = "ohio"
    region = "us-east-2"
}

# S3 버킷 생성 (가장 저렴한 버전)
resource "aws_s3_bucket" "my_s3_bucket" {
    bucket = "cloud-hammer-developers-team"
}

# S3 버킷에 버전 관리 활성화
resource "aws_s3_bucket_versioning" "my_s3_versioning" {
    bucket = aws_s3_bucket.my_s3_bucket.bucket

    versioning_configuration {
        status = "Enabled"
    }
}

# EC2 인스턴스 생성 (오하이오 지역)
resource "aws_instance" "AWS-my-EC2-OH" {
    provider      = aws.ohio  # 오하이오 지역 설정을 사용
    ami           = "ami-06d4b7182ac3480fa"
    instance_type = "t2.micro"
    # subnet_id     = aws_subnet.AWS-my-subnet-A.id

    tags = {
        Name = "AWS-my-EC2-OH"
    }

    # 보안 그룹 설정
    # vpc_security_group_ids = [aws_security_group.AWS-my-sg.id]
}
 */