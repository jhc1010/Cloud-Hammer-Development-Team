# Azure Provider 설정
provider "azurerm" {
  features {}
  subscription_id    = jsondecode(file("azure.json")).azure_credentials.subscription_id
  client_id          = jsondecode(file("azure.json")).azure_credentials.client_id
  client_secret      = jsondecode(file("azure.json")).azure_credentials.client_secret
  tenant_id          = jsondecode(file("azure.json")).azure_credentials.tenant_id
}

# 공통 리소스 그룹
resource "azurerm_resource_group" "common" {
  name     = "Azure-ServerGroup"
  location = "koreacentral"

  tags = {
    environment = "Terraform Demo"
  }
}

# 공용 네트워크
resource "azurerm_virtual_network" "common" {
  name                = "Azure-Vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  tags = {
    environment = "Terraform Demo"
  }
}

# 공용 서브넷
resource "azurerm_subnet" "common" {
  name                 = "Azure-Subnet"
  resource_group_name  = azurerm_resource_group.common.name
  virtual_network_name = azurerm_virtual_network.common.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 공용 공용 IP
resource "azurerm_public_ip" "common" {
  name                = "commonPublicIP"
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
  allocation_method   = "Static"

  tags = {
    environment = "Terraform Demo"
  }
}

# 공용 로드 밸런서
resource "azurerm_lb" "common" {
  name                = "Azure-LB"
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.common.id
  }
}

# 공용 네트워크 보안 그룹 및 규칙
resource "azurerm_network_security_group" "common" {
  name                = "Azure-NSG"
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform Demo"
  }
}

# 가상 머신 스케일 세트 및 자동 스케일 설정
resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = "Azure-Server"
  location            = azurerm_resource_group.common.location
  resource_group_name = azurerm_resource_group.common.name
  upgrade_mode        = "Manual"
  sku                 = "Standard_F2"
  instances           = 2  # 인스턴스 개수를 3으로 변경

  admin_username      = "myadmin"

  admin_ssh_key {
    username   = "myadmin"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCsTcryUl51Q2VSEHqDRNmceUFo55ZtcIwxl2QITbN1RREti5ml/VTytC0yeBOvnZA4x4CFpdw/lCDPk0yrH9Ei5vVkXmOrExdTlT3qI7YaAzj1tUVlBd4S6LX1F7y6VLActvdHuDDuXZXzCDd/97420jrDfWZqJMlUK/EmCE5ParCeHIRIvmBxcEnGfFIsw8xQZl0HphxWOtJil8qsUWSdMyCiJYYQpMoMliO99X40AUc4/AlsyPyT5ddbKk08YrZ+rKDVHF7o29rh4vi5MmHkVgVQHKiKybWlHq+b71gIAUQk9wrJxD+dqt4igrmDSpIjfjwnd+l5UIn5fJSO5DYV4YT/4hwK7OKmuo7OFHD0WyY5YnkYEMtFgzemnRBdE8ulcT60DQpVgRMXFWHvhyCWy0L6sgj1QWDZlLpvsIvNfHsyhKFMG1frLnMt/nP0+YCcfg+v1JYeCKjeoJxB8DWcRBsjzItY0CGmzP8UYZiYKl/2u+2TgFS5r7NWH11bxoUzjKdaa1NLw+ieA8GlBFfCbfWe6YVB9ggUte4VtYFMZGxOjS2bAiYtfgTKFJv+XqORAwExG6+G2eDxIDyo80/OA9IG7Xv/jwQr7D6KDjDuULFcN/iTxuttoKrHeYz1hf5ZQlBdllwJHYx6fK2g8kha6r2JIQKocvsAXiiONqSfw== hello@world.com"
  }

  network_interface {
    name    = "TestNetworkProfile"
    primary = true

    ip_configuration {
      name      = "TestIPConfiguration"
      primary   = true
      subnet_id = azurerm_subnet.common.id
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

# 자동 스케일 설정
resource "azurerm_monitor_autoscale_setting" "example" {
  name                = "Azure-AutoScaling"
  resource_group_name = azurerm_resource_group.common.name
  location            = azurerm_resource_group.common.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.example.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  predictive {
    scale_mode      = "Enabled"
    look_ahead_time = "PT5M"
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}

