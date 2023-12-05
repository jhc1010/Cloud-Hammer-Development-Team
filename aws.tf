# AWS 서비스 및 지역 설정 (서울 지역)
provider "aws" {
    region = "ap-northeast-2"
}

# VPC 리소스 생성
resource "aws_vpc" "my_vpc" {
    cidr_block = "172.16.0.0/16"
    tags = {
        Name = "myVPC"
    }
}

# Subnet 리소스 생성
resource "aws_subnet" "my_subnet" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.10.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "mySubnet"
    }
}

resource "aws_subnet" "my_another_subnet" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "172.16.20.0/24"
    availability_zone = "ap-northeast-2c"  # 다른 가용 영역 선택
    tags = {
        Name = "myAnotherSubnet"
    }
}

# Network Interface 리소스 생성
resource "aws_network_interface" "my_net" {
    subnet_id   = aws_subnet.my_subnet.id
    private_ips = ["172.16.10.100"]
    tags = {
        Name = "private_network_interface"
    }
}

# 오토스케일링에 사용될 Launch Configuration 생성
resource "aws_launch_configuration" "my_launch_config" {
    name                 = "myLaunchConfig"
    image_id             = "ami-01123b84e2a4fba05"
    instance_type        = "t2.micro"
    associate_public_ip_address = true  # 퍼블릭 IP 자동 할당 설정

    lifecycle {
        create_before_destroy = true
    }
}

# 로드밸런서 생성
resource "aws_lb" "my_lb" {
    name               = "myLoadBalancer"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.my_lb_sg.id]
    subnets            = [aws_subnet.my_subnet.id, aws_subnet.my_another_subnet.id]
    enable_deletion_protection = false
}

# 로드밸런서에 대한 보안 그룹 생성
resource "aws_security_group" "my_lb_sg" {
    name        = "myLoadBalancerSG"
    description = "Security group for my load balancer"
    vpc_id      = aws_vpc.my_vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22  # SSH 포트
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# 로드밸런서 타깃 그룹 생성
resource "aws_lb_target_group" "my_target_group" {
    name        = "myTargetGroup"
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = aws_vpc.my_vpc.id
}

# 로드밸런서에 오토스케일링 그룹과 타깃 그룹 추가
resource "aws_lb_listener" "my_listener" {
    load_balancer_arn = aws_lb.my_lb.arn
    port              = 80
    protocol          = "HTTP"

    default_action {
        target_group_arn = aws_lb_target_group.my_target_group.arn
        type             = "forward"
    }
}

# VPC에 대한 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
}

# VPC의 라우팅 테이블에 인터넷 게이트웨이를 추가
resource "aws_route" "route_to_igw" {
    route_table_id         = aws_vpc.my_vpc.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.my_igw.id
}

# 오토스케일링 그룹 생성
resource "aws_autoscaling_group" "my_asg" {
    desired_capacity     = 2
    max_size             = 3
    min_size             = 1
    vpc_zone_identifier = [aws_subnet.my_subnet.id, aws_subnet.my_another_subnet.id]
    launch_configuration = aws_launch_configuration.my_launch_config.id

    tag {
        key                 = "Name"
        value               = "myASG"
        propagate_at_launch = true
    }
}
