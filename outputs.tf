
//Display Bastion and Jumphost Login Details
output "bastion_login_command" {
  value = "ssh -i ~/.ssh/id_rsa ${var.bastion_username}@${oci_core_instance.bastion.public_ip}"
}

output "local_jumpbox_tunnel" {
  value = "ssh -i ~/.ssh/id_rsa ${var.jumphost_username}@${oci_core_instance.bastion.public_ip} -L 9999:${oci_core_instance.jumphost.private_ip}:3389"
}

output "jumpbox_username" {
  value = data.oci_core_instance_credentials.jumphost_credentials.username
}

output "jumpbox_password" {
  value = data.oci_core_instance_credentials.jumphost_credentials.password
}

//FSS Mount Command
output "FSS_Mount_Command" {
  value = "mount ${local.nfs_source_IP}:${var.fss_export_path}"
}

//Display SDDC Login Details
output "vcenter_fqdn" {
  value = oci_ocvp_sddc.sddc.vcenter_fqdn
}

output "vcenter_username" {
  value = oci_ocvp_sddc.sddc.vcenter_username
}

output "vcenter_initial_password" {
  value = oci_ocvp_sddc.sddc.vcenter_initial_password
}
