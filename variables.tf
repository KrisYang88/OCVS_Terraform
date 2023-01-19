variable "region" {}
variable "tenancy_ocid" {} 
variable "targetCompartment" {} 
variable "ad" {}
variable "ssh_key" { }
variable "use_custom_name" { default = false }
variable "cluster_name" { default = "" }

variable "use_existing_vcn" { default = false}
variable "vcn_compartment" { default = ""}
variable "vcn_id" { default = ""}
variable "public_subnet_id" { default = ""}
variable "private_subnet_id" { default = ""}
variable "vcn_subnet" { default = "172.16.0.0/16" }
variable "public_subnet" { default = "172.16.1.0/24" }
variable "private_subnet" { default = "172.16.2.0/24" }
variable "nat_gateway" { default = ""}
variable "ssh_cidr" { default = "0.0.0.0/0" }

variable "bastion_ad" {}
variable "bastion_shape" { default = "VM.Standard.E3.Flex" }
variable "bastion_image" {}
variable "bastion_ocpus" { default = 1 }
variable "bastion_custom_memory" { default = false }
variable "bastion_memory" { default = 16 }
variable "bastion_boot_volume_size" { default = 50 }
variable "bastion_username" { 
  type = string 
  default = "opc" 
}

variable "jumphost_ad" {}
variable "jumphost_shape" { default = "VM.Standard.E3.Flex" }
variable "jumphost_image" {}
variable "jumphost_ocpus" { default = 4 }
variable "jumphost_custom_memory" { default = false }
variable "jumphost_memory" { default = 32 }
variable "jumphost_boot_volume_size" { default = 50 }
variable "jumphost_username" { 
  type = string 
  default = "opc" 
} 

variable "esxi_host_shape" { default = "BM.DenseIO.E4.128" }
variable "esxi_e4_host_ocpus" { default = 64 }
variable "esxi_x7_host_ocpus" { default = 52 }
variable "is_single_host_sddc" { default = false }
variable "esxi_host_count" { default = 3 }
variable "is_hcx_enabled" { default = true }
variable "vmware_software_version" { default = "7.0 update 3" }
variable "sddc_initial_sku" { default = "MONTH" }
variable "is_shielded_instance_enabled" { default = false }


variable "sddc_workload_cidr" { default = "192.168.0.0/16" }
variable "is_default_provisioning_cidr_range" { default = true }
variable "sddc_provisioning_cidr" { default = "172.16.0.0/25" }
variable "vlan_nsx_edge_uplink1_cidr" { default = "172.16.3.0/25" }
variable "vlan_nsx_edge_uplink2_cidr" { default = "172.16.4.0/25" }
variable "vlan_nsx_edge_vtep_cidr" { default = "172.16.5.0/25" }
variable "vlan_nsx_vtep_cidr" { default = "172.16.6.0/25" }
variable "vlan_vmotion_cidr" { default = "172.16.7.0/25" }
variable "vlan_vsan_cidr" { default = "172.16.8.0/25" }
variable "vlan_vsphere_cidr" { default = "172.16.9.0/25" }
variable "vlan_hcx_cidr" { default = "172.16.10.0/25" }
variable "vlan_replication_cidr" { default = "172.16.11.0/25" }
variable "vlan_provisioning_cidr" { default = "172.16.12.0/25" }

variable "create_fss" { default = false }
variable "fss_compartment" {default = ""}
variable "fss_ad" {default = ""}
variable "fss_export_path" {default = "/NFSDatastore"}
variable "nfs_source_IP" { default = ""}