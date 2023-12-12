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
  credentials = jsondecode(file("ncp.json"))
}

# 네이버 클라우드 VPC 생성
resource "ncloud_vpc" "ncp-vpc" {
  ipv4_cidr_block    = "10.0.0.0/16"
  name               = "ncp-vpc"
}

# 네이버 클라우드 서브넷 생성
resource "ncloud_subnet" "ncp-subnet" {
  vpc_no             = ncloud_vpc.ncp-vpc.vpc_no
  subnet             = "10.0.0.0/24"
  zone               = "KR-2"
  network_acl_no     = ncloud_vpc.ncp-vpc.default_network_acl_no
  subnet_type        = "PUBLIC"
  usage_type         = "GEN"
  name               = "ncp-subnet"  
}

# 네이버 클라우드 Launch Configuration 생성
resource "ncloud_launch_configuration" "ncp-lc" {
  name                    = "nserver"  
  server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0703.B050"
  # server_product_code      = "SVR.VSVR.HICPU.C002.M004.NET.SSD.B050.G002"  #고성능 cpu
  server_product_code       = "SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002"   #표준 cpu
}

# 네이버 클라우드 Auto Scaling Group 생성
resource "ncloud_auto_scaling_group" "ncp-asg" {
  access_control_group_no_list = [ncloud_access_control_group.ncp-acg.id]
  subnet_no                    = ncloud_subnet.ncp-subnet.subnet_no
  launch_configuration_no      = ncloud_launch_configuration.ncp-lc.launch_configuration_no
  min_size                     = 1
  max_size                     = 1
  name                         = "ncp-autoscalinggroup"
  server_name_prefix           = "nserver"  
}

# 네이버 클라우드 액세스 컨트롤 그룹 생성
resource "ncloud_access_control_group" "ncp-acg" {
  name   = "ncp-accescontrlolgroup"
  vpc_no = ncloud_vpc.ncp-vpc.vpc_no
}

# 네이버 클라우드 액세스 컨트롤 그룹 규칙 생성 (SSH 허용)
resource "ncloud_access_control_group_rule" "ncp-acg-rule" {
  access_control_group_no = ncloud_access_control_group.ncp-acg.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"  # 모든 IP 허용 (실제 운영에서는 제한 필요)
    port_range  = "22"
    description = "SSH"
  }
}

