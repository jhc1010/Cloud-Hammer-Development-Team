# Azure Provider 설정
provider "azurerm" {
  features {}
  subscription_id    = jsondecode(file("azure.json")).azure_credentials.subscription_id
  client_id          = jsondecode(file("azure.json")).azure_credentials.client_id
  client_secret      = jsondecode(file("azure.json")).azure_credentials.client_secret
  tenant_id          = jsondecode(file("azure.json")).azure_credentials.tenant_id
}

# 리소스 그룹 생성
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"     # 리소스 그룹 이름
    location = "koreacentral"        # 리소스 그룹 위치 (지역)

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# 가상 네트워크 생성
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "azure-subnet"                           # 가상 네트워크 이름
    address_space       = ["10.0.0.0/16"]                     # IP 주소 공간
    location            = "koreacentral"                    # 가상 네트워크 위치
    resource_group_name = azurerm_resource_group.myterraformgroup.name  # 속한 리소스 그룹

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# 서브넷 생성
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "azure-subnet"                                       # 서브넷 이름
    resource_group_name  = azurerm_resource_group.myterraformgroup.name     # 속한 리소스 그룹
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name  # 속한 가상 네트워크
    address_prefixes     = ["10.0.0.0/24"]                                  # 서브넷 IP 주소 범위
}

# 공용 IP 생성
resource "azurerm_public_ip" "myterraformpublicip" {
    name                = "myPublicIP"                                     # 공용 IP 이름
    location            = "koreacentral"                                  # 공용 IP 위치
    resource_group_name = azurerm_resource_group.myterraformgroup.name     # 속한 리소스 그룹
    allocation_method   = "Dynamic"                                       # IP 할당 방법

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# 네트워크 보안 그룹 및 규칙 생성
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "auzre-sg"      # 네트워크 보안 그룹 이름
    location            = "koreacentral"               # 네트워크 보안 그룹 위치
    resource_group_name = azurerm_resource_group.myterraformgroup.name  # 속한 리소스 그룹

    security_rule {
        name                       = "SSH"                  # 보안 규칙 이름
        priority                   = 1001                   # 우선순위
        direction                  = "Inbound"              # 트래픽 방향 (입력)
        access                     = "Allow"                # 허용
        protocol                   = "Tcp"                  # 프로토콜
        source_port_range          = "*"                    # 출발지 포트 범위
        destination_port_range     = "22"                   # 목적지 포트
        source_address_prefix      = "*"                    # 출발지 주소 범위
        destination_address_prefix = "*"                    # 목적지 주소 범위
    }

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# 네트워크 인터페이스 생성
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "azure-NIC"                                        # 네트워크 인터페이스 이름
    location                  = "koreacentral"                                # 네트워크 인터페이스 위치
    resource_group_name       = azurerm_resource_group.myterraformgroup.name  # 속한 리소스 그룹

    ip_configuration {
        name                          = "myNicConfiguration"                       # IP 구성 이름
        subnet_id                     = azurerm_subnet.myterraformsubnet.id        # 속한 서브넷
        private_ip_address_allocation = "Dynamic"                                # 동적 사설 IP 할당
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id  # 속한 공용 IP
    }

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# 보안 그룹을 네트워크 인터페이스에 연결
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id           # 속한 네트워크 인터페이스
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id     # 연결할 네트워크 보안 그룹
}

# 고유한 스토리지 계정 이름을 생성하기 위한 무작위 텍스트 생성
resource "random_id" "randomId" {
    keepers = {
        # 리소스 그룹이 정의될 때만 새로운 ID를 생성
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# 부팅 진단을 위한 스토리지 계정 생성
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"               # 스토리지 계정 이름
    resource_group_name         = azurerm_resource_group.myterraformgroup.name  # 속한 리소스 그룹
    location                    = "koreacentral"                              # 스토리지 계정 위치
    account_tier                = "Standard"                                  # 계정 계층
    account_replication_type    = "LRS"                                       # 계정 복제 유형

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}

# SSH 키 생성 (생성 및 출력)
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}

# 가상 머신 생성
resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "azure-server"                                           # 가상 머신 이름
    location              = "koreacentral"                                  # 가상 머신 위치
    resource_group_name   = azurerm_resource_group.myterraformgroup.name     # 속한 리소스 그룹
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]    # 사용할 네트워크 인터페이스 ID 목록
    size                  = "Standard_DS1_v2"                               # 가상 머신 크기

    os_disk {
        name              = "myOsDisk"                                    # OS 디스크 이름
        caching           = "ReadWrite"                                   # 캐싱 설정
        storage_account_type = "Premium_LRS"                              # 스토리지 계정 유형
    }

    source_image_reference {
        publisher = "Canonical"                                            # 이미지 공급자
        offer     = "UbuntuServer"                                        # 이미지 옵션
        sku       = "18.04-LTS"                                            # 이미지 SKU
        version   = "latest"                                               # 이미지 버전
    }

    computer_name  = "azure-server"                                                # 컴퓨터 이름
    admin_username = "azureuser"                                          # 관리자 사용자 이름
    disable_password_authentication = true                               # 비밀번호 인증 비활성화

    admin_ssh_key {
        username       = "azureuser"                                      # SSH 키 사용자 이름
        public_key     = tls_private_key.example_ssh.public_key_openssh   # SSH 공개 키
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint  # 부팅 진단을 위한 스토리지 계정 URI
    }

    tags = {
        environment = "Terraform Demo"  # 태그: 환경
    }
}
