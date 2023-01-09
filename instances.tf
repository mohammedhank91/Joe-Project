# create ip address for 4 nodes

resource "google_compute_address" "static" {
  count = "${var.node_count}"
  name = "rancher-work-${count.index}"
  project = var.project
  region = var.region
}
resource "google_compute_instance" "rancher" {
  count = "${var.node_count}"
    boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }
  name = "rancher-work-${count.index}"
  machine_type = "${var.machine_type}" 
  zone         = "${var.region_zone}"
  tags         = ["k8s-node"]
 
  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.static.*.address[count.index]}"
    }
  }
    metadata = {
    ssh-keys = "root:${file("${var.public_key_path}")}"
  }
# We create a public IP address for our google compute instance to utilize
 provisioner "file" {
    source      = "${var.install_script_src_path}"
    destination = "${var.install_script_dest_path}"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
    }
  }
    provisioner "remote-exec" {
        inline = [
          "chmod +x /tmp/install.sh",
          "/tmp/install.sh ${count.index} ${google_compute_address.static.*.address[count.index]} ${var.rs_proj_name}"
        ]
    }
    connection { 
      type        = "ssh"
      user        = "root"
      private_key = "${file("${var.private_key_path}")}"
      agent       = false
      host  = "${google_compute_address.static.*.address[count.index]}"
    }

}

 