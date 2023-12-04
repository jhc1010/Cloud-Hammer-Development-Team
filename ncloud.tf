# Terraform 초기화
terraform {                                                                   # Terraform 설정의 시작을 알리는 부분
  required_providers {                                                        # 필요한 프로바이더를 지정하여 Terraform이 해당 클라우드 또는 서비스와 상호작용할 수 있도록 함
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"                                                # Terraform 엔진의 최소 버전을 지정합니다.
}

locals {
  credentials = jsondecode(file("naver.json"))
}

provider "ncloud" {
  access_key = local.credentials.naver_v0.accessKeyId
  secret_key = local.credentials.naver_v0.secretKey
  region     = "KR"
  site       = "public"
  support_vpc = true
}


# 네이버 클라우드 VPC 생성
resource "ncloud_vpc" "vpc" {
  ipv4_cidr_block = "172.16.0.0/16"                                           # VPC의 IP 대역 설정
  name            = "test-vpc"                                                # VPC의 이름
}

# 네이버 클라우드 서브넷 생성
resource "ncloud_subnet" "public-subnet" {
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "172.16.10.0/24"                                           # 서브넷의 IP 대역 설정
  zone           = "KR-2"                                                     # 존 (Zone) 설정
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PUBLIC"                                                   # 서브넷 유형 (PUBLIC)
  name           = "public-a-subnet"                                          # 서브넷의 이름
  usage_type     = "GEN"                                                      # 사용 유형 (GEN)
}

# 네이버 클라우드 서버 생성
resource "ncloud_server" "public-server" {
  subnet_no                 = ncloud_subnet.public-subnet.id
  name                      = "test-web01"                                    # 서버의 이름
  # server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0708.B050"              # CentOS 이미지 사용 7.8버전
  server_image_product_code = "SW.VSVR.OS.LNX64.CNTOS.0703.B050"              # CentOS 이미지 사용 7.3버전  3분58초

  # server_product_code       = "SVR.VSVR.HICPU.C002.M004.NET.HDD.B050.G002"  # 고성능 CPU 서버 사용        4분47초
  #  미입력시 가장낮은스펙적용   4분27초

  login_key_name            = "ncp20231116"                                   # 로그인 키 이름
}


# 네이버 클라우드 공인 IP 생성
resource "ncloud_public_ip" "public-ip" {                                     # 공인 IP는 외부에서 서버에 접근할 때 사용되는 IP 주소

  
  server_instance_no = ncloud_server.public-server.id                         #  공인 IP를 어떤 서버와 연결할지를 설정
}

# 네이버 클라우드 액세스 컨트롤 그룹 생성
resource "ncloud_access_control_group" "test-acg" {                           # 액세스 컨트롤 그룹은 서버와 관련된 보안 규칙을 설정하는데 사용
  name   = "test-acg"                                                         # 이 액세스 컨트롤 그룹의 이름은 "test-acg"로 지정
  vpc_no = ncloud_vpc.vpc.id                                                  # 이 액세스 컨트롤 그룹을 만들 때 어떤 VPC를 사용할지를 설정
}

# 네이버 클라우드 액세스 컨트롤 그룹 규칙 생성
resource "ncloud_access_control_group_rule" "test-acg-rule" {                # 네이버 클라우드에서 액세스 컨트롤 그룹에 규칙을 추가하는 코드
  access_control_group_no = ncloud_access_control_group.test-acg.id          # 규칙을 어떤 액세스 컨트롤 그룹에 추가할지를 설정

  # SSH 트래픽만 허용
  inbound {                                                                  # 액세스 컨트롤 그룹 규칙에 SSH 트래픽을 허용하는 설정
    protocol    = "TCP"                                                      # TCP 프로토콜을 사용하며, 모든 IP 주소 (0.0.0.0/0)에서 SSH 포트 (22)로의 연결을 허용
    ip_block    = "0.0.0.0/0"
    port_range  = "22"
    description = "SSH"
  }
}

# 네이버 클라우드 라우팅 테이블 연결
resource "ncloud_route_table_association" "route_ass_public" {            # 네이버 클라우드의 라우팅 테이블을 설정하는 코드
  route_table_no = ncloud_vpc.vpc.default_public_route_table_no           # 어떤 라우팅 테이블과 어떤 서브넷을 연결할지를 설정
  subnet_no      = ncloud_subnet.public-subnet.id
}

  