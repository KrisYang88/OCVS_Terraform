resource "oci_core_instance" "bastion" {
  depends_on          = [local.bastion_subnet_id]
  availability_domain = var.bastion_ad
  compartment_id      = var.targetCompartment
  shape               = var.bastion_shape

  dynamic "shape_config" {
    for_each = local.is_bastion_flex_shape
      content {
        ocpus = shape_config.value
        memory_in_gbs = var.bastion_custom_memory ? var.bastion_memory : 16 * shape_config.value
      }
  }
  agent_config {
    is_management_disabled = true
    }
  display_name        = "${local.cluster_name}-bastion"

  freeform_tags = {
    "cluster_name" = local.cluster_name
    "parent_cluster" = local.cluster_name
  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_key}\n${tls_private_key.ssh.public_key_openssh}"
    user_data           = base64encode(data.template_file.bastion_config.rendered)
  }

  source_details {
    source_id = var.bastion_image
    boot_volume_size_in_gbs = var.bastion_boot_volume_size
    source_type = "image"
  }

  create_vnic_details {
    assign_public_ip = "true"
    subnet_id = local.bastion_subnet_id
  }
} 

resource "null_resource" "bastion" { 
  depends_on = [oci_core_instance.bastion] 
  triggers = { 
    bastion = oci_core_instance.bastion.id
  } 

  provisioner "file" {
    content     = tls_private_key.ssh.private_key_pem
    destination = "/home/${var.bastion_username}/.ssh/id_rsa"
    connection {
      timeout     = "5m"    
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = ["chmod 600 /home/${var.bastion_username}/.ssh/id_rsa"]
    connection {
      timeout     = "5m"      
      host        = oci_core_instance.bastion.public_ip
      type        = "ssh"
      user        = var.bastion_username
      private_key = tls_private_key.ssh.private_key_pem
    }
  }
}
