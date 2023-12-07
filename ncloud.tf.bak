# Terraform 초기화
terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"
}

# 네이버 클라우드 프로바이더 설정
provider "ncloud" {
  access_key  = local.credentials.naver_v0.accessKeyId
  secret_key  = local.credentials.naver_v0.secretKey
  region      = "KR"
  site        = "public"
  support_vpc = true
}

locals {
  credentials = jsondecode(file("naver.json"))
}

# 네이버 클라우드 VPC 생성
resource "ncloud_vpc" "example" {
  ipv4_cidr_block    = "10.0.0.0/16"
  name               = "example-vpc"
}

# 네이버 클라우드 서브넷 생성
resource "ncloud_subnet" "example" {
  vpc_no             = ncloud_vpc.example.vpc_no
  subnet             = "10.0.0.0/24"
  zone               = "KR-2"
  network_acl_no     = ncloud_vpc.example.default_network_acl_no
  subnet_type        = "PUBLIC"
  usage_type         = "GEN"
}

# 네이버 클라우드 서버 생성
resource "ncloud_server" "example-server" {
  subnet_no           = ncloud_subnet.example.subnet_no
  name                = "test-web01"
  server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0703.B050"
  login_key_name      = "ncp20231116"
}

# 네이버 클라우드 공인 IP 생성
resource "ncloud_public_ip" "example-public-ip" {
  server_instance_no = ncloud_server.example-server.id
}

# 네이버 클라우드 액세스 컨트롤 그룹 생성
resource "ncloud_access_control_group" "example-acg" {
  name   = "example-acg"
  vpc_no = ncloud_vpc.example.vpc_no
}

# 네이버 클라우드 액세스 컨트롤 그룹 규칙 생성
resource "ncloud_access_control_group_rule" "example-acg-rule" {
  access_control_group_no = ncloud_access_control_group.example-acg.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "22"
    description = "SSH"
  }
}

# 네이버 클라우드 Launch Configuration 생성
resource "ncloud_launch_configuration" "lc" {
  name                    = "my-lc"
  server_image_product_code = "SPSW0LINUX000046"
  server_product_code      = "SPSVRSSD00000003"
}

# 네이버 클라우드 Auto Scaling Group 생성
resource "ncloud_auto_scaling_group" "example_asg" {
  name                     = "my-auto"
  launch_configuration_no = ncloud_launch_configuration.lc.launch_configuration_no
  min_size                 = 1
  max_size                 = 1
  zone_no_list             = ["2"]
  wait_for_capacity_timeout = "0"
}

#ncp작업중