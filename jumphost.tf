resource "oci_core_instance" "jumphost" {
  depends_on          = [local.jumphost_subnet_id]
  availability_domain = var.jumphost_ad
  compartment_id      = var.targetCompartment
  shape               = var.jumphost_shape

  dynamic "shape_config" {
    for_each = local.is_jumphost_flex_shape
      content {
        ocpus = shape_config.value
        memory_in_gbs = var.jumphost_custom_memory ? var.jumphost_memory : 32 * shape_config.value
      }
  }
  agent_config {
    is_management_disabled = true
    }

  display_name        = "${local.cluster_name}-jumphost"

  freeform_tags = {
    "cluster_name" = local.cluster_name
    "parent_cluster" = local.cluster_name
  }

  source_details {
    #source_id = data.oci_core_images.windows-2022-vm.images.0.id
    source_id = var.jumphost_image
    boot_volume_size_in_gbs = var.jumphost_boot_volume_size
    source_type = "image"
  }

  create_vnic_details {
    assign_public_ip = "false"
    subnet_id = local.jumphost_subnet_id
  }
} 