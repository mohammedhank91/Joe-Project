output "masterip" {
  value = "${google_compute_address.static.*.address[0]}"
}