resource "random_pet" "name" {
  length = 2
}

resource "random_string" "string" {
  length  = 6
  special = false
  upper   = false
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

data "oci_core_services" "services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_vcn" "vcn" { 
  vcn_id = local.vcn_id
} 

data "oci_core_instance_credentials" "jumphost_credentials" {
    instance_id = oci_core_instance.jumphost.id
}

data "oci_ocvp_supported_skus" "supported_skus" {
  compartment_id = "${var.targetCompartment}"
}

data "oci_ocvp_supported_vmware_software_versions" "supported_vmware_software_versions" {
  compartment_id = "${var.targetCompartment}"
}