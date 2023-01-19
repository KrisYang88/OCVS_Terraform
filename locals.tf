locals { 

// infrastructure naming
  cluster_name = var.use_custom_name ? var.cluster_name : random_pet.name.id
  sddc_name = var.use_custom_name ? var.cluster_name : random_string.string.id

// vcn id derived either from created vcn or existing if specified
  vcn_id = var.use_existing_vcn ? var.vcn_id : element(concat(oci_core_vcn.vcn.*.id, [""]), 0)

// subnet id derived either from created subnet or existing if specified
  bastion_subnet_id = var.use_existing_vcn ? var.public_subnet_id : element(concat(oci_core_subnet.public-subnet.*.id, [""]), 0)
  jumphost_subnet_id = var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)
  fss_subnet_id = var.use_existing_vcn ? var.private_subnet_id : element(concat(oci_core_subnet.private-subnet.*.id, [""]), 0)

// nat, internet, service gateway variables
  natgw_id = var.use_existing_vcn ? var.nat_gateway : element(concat(oci_core_nat_gateway.ngw.*.id, [""]), 0)

// determine if bastion and jumphost are flex shapes
  is_bastion_flex_shape = length(regexall(".*VM.*.*Flex$", var.bastion_shape)) > 0 ? [var.bastion_ocpus]:[]
  is_jumphost_flex_shape = length(regexall(".*VM.*.*Flex$", var.jumphost_shape)) > 0 ? [var.jumphost_ocpus]:[]

// choose correct ocpu's for esxi shape
  esxi_host_count = var.is_single_host_sddc ? 1 : var.esxi_host_count
  esxi_host_ocpus = var.esxi_host_shape == "BM.DenseIO.E4.128" ? var.esxi_e4_host_ocpus : var.esxi_x7_host_ocpus

// fss
  nfs_source_IP = var.create_fss ? element(concat(oci_file_storage_mount_target.FSSMountTarget.*.ip_address, [""]), 0) : var.nfs_source_IP

}
