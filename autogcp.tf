# Google Cloud Provider 설정
provider "google" {
  credentials = file("gcp_key.json") # GCP에 로그인하기 위한 키 파일 경로
  project     = "multi-cloud-406002"  # 사용할 프로젝트 ID
  region      = "us-central1"         # 인스턴스를 배포할 지역
  zone        = "us-central1-a"       # 인스턴스를 배포할 존
}

# 가상 머신 템플릿 설정
resource "google_compute_instance_template" "instance_template" {
  name        = "example-template"                     # 템플릿의 이름
  description = "Instance Template for Auto Scaling"   # 템플릿의 설명

  machine_type = "f1-micro"                            # 인스턴스 크기
  disk {
    source_image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20210429" # 부팅 디스크 설정
  }

  network_interface {
    network = "default"  # 기본 네트워크 사용
  }
}

# 인스턴스 그룹 매니저 설정
resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "my-instance-group-manager"     # 인스턴스 그룹 매니저의 이름
  base_instance_name = "my-instance-group"             # 각 인스턴스의 이름
  target_size        = 2                               # 인스턴스 그룹 매니저가 관리하는 인스턴스의 목표 크기

  version {
    instance_template = google_compute_instance_template.instance_template.self_link # 사용할 템플릿 버전
    name              = "v1"
  }

  named_port {
    name = "http"      # 로드 밸런서와 연결된 포트
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.my_health_check.self_link  # 헬스 체크에 사용할 URL
    initial_delay_sec = 300                                                  # 문제가 발생한 인스턴스를 재시작하기 전 대기 시간
  }
}

# 헬스 체크 설정
resource "google_compute_health_check" "my_health_check" {
  name               = "my-uptime"          # 헬스 체크의 이름
  check_interval_sec = 1                    # 각 체크 간의 시간 간격
  timeout_sec        = 1                    # 각 체크의 타임아웃

  tcp_health_check {
    port = 80                               # TCP 포트 80에서의 헬스 체크
  }
}
