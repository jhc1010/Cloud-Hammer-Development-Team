# Google Cloud Provider 설정
provider "google" {
  credentials = file("gcp_key.json") # GCP에 로그인하기 위한 키 파일 경로
  project     = "airy-runway-405810"  # 사용할 프로젝트 ID
  region      = "us-central1"         # 인스턴스를 배포할 지역
  zone        = "us-central1-a"       # 인스턴스를 배포할 존
}
# 추가 리전을 위한 Google Cloud Provider 설정
// provider "google" {
//    alias       = "additional_region"
//   credentials = file("gcp_key.json")
//   project     = "multi-cloud-406002"
//   region      = "asia-northeast1"  # 추가 리전 설정
//   zone        = "asia-northeast1-a"
// }

// resource "google_storage_bucket" "my_bucket" {
//   name     = "my-unique-bucket-name"  # 고유한 이름으로 변경
//   location = "us-central1"                      # 버킷의 지역 설정, 필요에 따라 변경
// }
# VPC (가상 사설 클라우드 네트워크) 생성
resource "google_compute_network" "GCP-VPC" {
  name = "gcp-vpc"
}

# 서브넷 생성
resource "google_compute_subnetwork" "GCP-Subnet" {
  name          = "gcp-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.GCP-VPC.self_link
  region        = "us-central1"  # 원하는 지역으로 변경
}

# 네트워크 방화벽 생성
resource "google_compute_firewall" "GCP-SecurityGroup" {
  name    = "gcp-security-group"
  network = google_compute_network.GCP-VPC.self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # 다른 규칙 설정...

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-http"]
}


# 가상 머신 템플릿 설정
resource "google_compute_instance_template" "GCP-template" {
  name        = "gcp-server-template"                     # 템플릿의 이름
  description = "Instance Template for Auto Scaling"   # 템플릿의 설명

  machine_type = "f1-micro"                            # 인스턴스 크기
  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20210429" # 부팅 디스크 설정
  }

  network_interface {
    network = "default"  # 기본 네트워크 사용
  }
   metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y nginx
    sudo service nginx start
  SCRIPT
}

# 인스턴스 그룹 매니저 설정
resource "google_compute_instance_group_manager" "GCP-AutoScaling" {
  // provider = google.additional_region  # 추가 리전 Provider 사용
  name               = "gcp-auto-scaling-manager"     # 인스턴스 그룹 매니저의 이름
  base_instance_name = "gcp-instance-group"             # 각 인스턴스의 이름
  target_size        = 3                             # 인스턴스 그룹 매니저가 관리하는 인스턴스의 목표 크기

  version {
    instance_template = google_compute_instance_template.GCP-template.self_link # 사용할 템플릿 버전
    name              = "v1"
  }

  named_port {
    name = "http"      # 로드 밸런서와 연결된 포트
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.GCP-HealthCheck.self_link  # 헬스 체크에 사용할 URL
    initial_delay_sec = 300                                                  # 문제가 발생한 인스턴스를 재시작하기 전 대기 시간
  }
}

# 헬스 체크 설정
resource "google_compute_health_check" "GCP-HealthCheck" {
  // provider = google.additional_region  # 추가 리전 Provider 사용
  name               = "gcp-uptime-check"          # 헬스 체크의 이름
  check_interval_sec = 1                    # 각 체크 간의 시간 간격
  timeout_sec        = 1                    # 각 체크의 타임아웃

  tcp_health_check {
    port = 80                               # TCP 포트 80에서의 헬스 체크
  }
}
