Terraform-Azure 구축 가이드
====

# Azure CLI 설치
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

# 계정 생성 및 구독
https://portal.azure.com/ 접속 후 구독 생성

# 계정과 연동
```
az login --use-device-code

az account set --subscription "id의 코드를 친다"
```

# Terraform용 Service Principal 생성
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/id의 코드를 친다"
```

# 환경변수
```
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"

export ARM_TENANT_ID="<azure_subscription_tenant_id>"

export ARM_CLIENT_ID="<service_principal_appid>"

export ARM_CLIENT_SECRET="<service_principal_password>"
```

# 변경된 .bashrc 파일을 적용
```
source ~/.bashrc
```

# 환경변수가 제대로 추가되었는지 확인
```
printenv | grep ^ARM*
```

# Terraform을 실행할 Directory를 생성
```
mkdir demo-vm && cd demo-vm
```

# main.tf파일 생성
```
vi azure.tf
```

# Terraform 명령어를 실행
```
terraform init

terraform plan

terraform apply -auto-approve
```

# 명령어를 통해 SSH Private Key를 파일로 저장
```
terraform output -raw tls_private_key > demo-vm-private-key
chmod 400 demo-vm-private-key
```

# ssh로 VM에 연결이 가능한지 확인
```
ssh -i demo-vm-private-key azureuser@퍼블릭 IP주소
```

# 모든 리소스를 삭제
```
terraform destroy -auto-approve
