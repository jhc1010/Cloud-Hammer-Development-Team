provider "google" {
    credentials = file("gcp.json")

    project = "multi-cloud-406002"
    region  = "us-central1"
    zone    = "us-central1-a"
}

resource "google_compute_network" "vpc_network" {
    name = "terraform-network"
}

resource "google_compute_instance" "vm_instance" {
    name         = "terraform-instance"
    machine_type = "f1-micro"
    metadata = {
        ssh-keys = "root:${file("../../Downloads/multi-cloud-406002.pub")}"
    }

    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-11"
        }
    }

    network_interface {
        network = google_compute_network.vpc_network.name
        access_config {
        }
    }
}

resource "google_compute_firewall" "ssh" {
  name = "allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

output "gcp_vm_public_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
}



