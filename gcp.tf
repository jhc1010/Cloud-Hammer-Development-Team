// provider "google" {
//     credentials = file("gcp_key.json")

//     project = "multi-cloud-406002"
//     region  = "us-central1"
//     zone    = "us-central1-a"
// }


// resource "google_compute_instance" "vm_instance" {
//     name         = "terraform-instance2"
//     machine_type = "f1-micro"
//     //ssh-keys = "root:${file("/C:/Users/Admin/Downloads/multi-cloud-406002.pub")}"
//     // metadata = {
//     //     ssh-keys = "root:${file("${path.module}/.ssh/multi-cloud-406002.pub.")}"
//     // }

//     boot_disk {
//         initialize_params {
//             image = "debian-cloud/debian-11"
//         }
//     }

//     network_interface {
//         network = "default"
//         access_config {
//         }
//     }
// }


// output "gcp_vm_public_ip" {
//   value = google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip
// }
