# --------- Security List for SDDC
resource "oci_core_security_list" "sddc-security-list" {
  vcn_id         = local.vcn_id
  display_name   = "${local.sddc_name}_SL_sddc"
  compartment_id = var.targetCompartment

  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_subnet
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.ssh_cidr
    tcp_options {
      max = "22"
      min = "22"
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# --------- Create Route Table Rules for SDDC Subnet
resource "oci_core_route_table" "sddc_route_table" {
  display_name   = "${local.sddc_name}_RT_sddc"
  compartment_id = var.targetCompartment
  vcn_id         = local.vcn_id

  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}


# --------- Create Provisioning Subnet
resource "oci_core_subnet" "provisioning-subnet" {
  # availability_domain      = var.ad
  vcn_id                     = local.vcn_id
  compartment_id             = var.targetCompartment
  cidr_block                 = trimspace(var.sddc_provisioning_cidr)
  security_list_ids          = [oci_core_security_list.sddc-security-list.id]
  dns_label                  = "provisioning"
  display_name               = "${local.sddc_name}_provisioning_subnet"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.sddc_route_table.id
}


# --------- NSX-Edge-Uplink-1 VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-NSX-Edge-Uplink-1" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_VLAN-NSX-Edge-Uplink-1_RT"
  vcn_id         = local.vcn_id
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}
resource "oci_core_network_security_group" "NSG-for-NSX-Edge-Uplink-1" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-NSX-Edge-Uplink-1"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-1_SL1" {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-1_SL2"  {
  description               = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-1_SL3"  {
  description = "Allow ssh traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-1_SL4"  {
  description               = "ICMP traffic for: 3, 4 Destination Unreachable: Fragmentation Needed and Don't Fragment was Set"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  icmp_options {
    code = "4"
    type = "3"
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-1_SL5"  {
  description = "ICMP traffic for: 3 Destination Unreachable"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  icmp_options {
    code = "-1"
    type = "3"
  }
}
resource "oci_core_vlan" "VLAN-NSX-Edge-Uplink-1" {
  availability_domain = var.ad
  cidr_block          = var.vlan_nsx_edge_uplink1_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-NSX-Edge-Uplink-1"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-1.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-NSX-Edge-Uplink-1.id
  vcn_id         = local.vcn_id
  vlan_tag       = "158"
}



# --------- NSX-Edge-Uplink-2 VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-NSX-Edge-Uplink-2" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_VLAN-NSX-Edge-Uplink-2_RT"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group" "NSG-for-NSX-Edge-Uplink-2" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-NSX-Edge-Uplink-2"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-2_SL1" {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-2_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-2_SL3"  {
  description = "Allow ssh traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-2_SL4"  {
  description               = "ICMP traffic for: 3, 4 Destination Unreachable: Fragmentation Needed and Don't Fragment was Set"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  icmp_options {
    code = "4"
    type = "3"
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-Uplink-2_SL5"  {
  description               = "ICMP traffic for: 3 Destination Unreachable"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  icmp_options {
    code = "-1"
    type = "3"
  }
}
resource "oci_core_vlan" "VLAN-NSX-Edge-Uplink-2" {
  availability_domain = var.ad
  cidr_block          = var.vlan_nsx_edge_uplink2_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-NSX-Edge-Uplink-2"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-Edge-Uplink-2.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-NSX-Edge-Uplink-2.id
  vcn_id              = local.vcn_id
  vlan_tag            = "258"
}



# --------- NSX-Edge-VTEP VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-NSX-Edge-VTEP" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_VLAN-NSX-Edge-VTEP_RT"
  vcn_id         = local.vcn_id
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}
resource "oci_core_network_security_group" "NSG-for-NSX-Edge-VTEP" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-NSX-Edge-VTEP"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-VTEP_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-VTEP.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-VTEP_SL2"  {
  description               = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-VTEP.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-VTEP_SL3"  {
  description = "Allow traffic for GENEVE Termination End Point (TEP) Transport N/W"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-VTEP.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6081"
      min = "6081"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-Edge-VTEP_SL4"  {
  description = "Allow traffic for BFD Session between TEPs"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-Edge-VTEP.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
  }
}
resource "oci_core_vlan" "VLAN-NSX-Edge-VTEP" {
  availability_domain = var.ad
  cidr_block          = var.vlan_nsx_edge_vtep_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-NSX-Edge-VTEP"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-Edge-VTEP.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-NSX-Edge-VTEP.id
  vcn_id              = local.vcn_id
  vlan_tag            = "358"
}



# --------- NSX-VTEP VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-NSX-VTEP" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_VLAN-NSX-VTEP_RT"
  vcn_id         = local.vcn_id
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}
resource "oci_core_network_security_group" "NSG-for-NSX-VTEP" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-NSX-VTEP"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-VTEP_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-VTEP.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-VTEP_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-VTEP.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-VTEP_SL3"  {
  description = "Allow traffic for GENEVE Termination End Point (TEP) Transport N/W"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-VTEP.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6081"
      min = "6081"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-NSX-VTEP_SL4"  {
  description = "Allow traffic for BFD Session between TEPs"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-NSX-VTEP.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
  }
}
resource "oci_core_vlan" "VLAN-NSX-VTEP" {
  availability_domain = var.ad
  cidr_block          = var.vlan_nsx_vtep_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-NSX-VTEP"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-NSX-VTEP.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-NSX-VTEP.id
  vcn_id              = local.vcn_id
  vlan_tag            = "458"
}



# --------- vMotion VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-vMotion" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_vMotion_RT"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group" "NSG-for-vMotion" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-vMotion"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vMotion_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vMotion.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vMotion_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vMotion.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vMotion_SL3"  {
  description = "Allow ESXi NFC traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vMotion.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vMotion_SL4"  {
  description = "Allow HTTPS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vMotion.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vMotion_SL5"  {
  description = "Allow vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vMotion.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_vlan" "VLAN-vMotion" {
  availability_domain = var.ad
  cidr_block          = var.vlan_vmotion_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-vMotion"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-vMotion.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-vMotion.id
  vcn_id              = local.vcn_id
  vlan_tag            = "558"
}




# --------- vSAN VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-vSAN" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_vSAN_RT"
  vcn_id         = local.vcn_id
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}
resource "oci_core_network_security_group" "NSG-for-vSAN" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-vSAN"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL3"  {
  description = "Allow traffic used for Virtual SAN health monitoring"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL4"  {
  description = "Allow traffic used for Virtual SAN health monitoring"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL5"  {
  description = "Allow vSAN HTTP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL6"  {
  description = "Allow vSAN Transport traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL7"  {
  description = "Allow vSAN Clustering Service traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12345"
      min = "12345"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL8"  {
  description = "Allow Unicast agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSAN_SL9"  {
  description = "Allow vSAN Clustering Service traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSAN.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "23451"
    }
  }
}
resource "oci_core_vlan" "VLAN-vSAN" {
  availability_domain = var.ad
  cidr_block          = var.vlan_vsan_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-vSAN"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-vSAN.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-vSAN.id
  vcn_id         = local.vcn_id
  vlan_tag       = "658"
}



# --------- HCX VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-HCX" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_HCX_RT"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group" "NSG-for-HCX" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-HCX"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL3"  {
  description = "Allow HCX bulk migration traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "31031"
      min = "31031"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL4"  {
  description = "Allow HCX X-cloud vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL5"  {
  description = "Allow HCX X-cloud control traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL6"  {
  description = "Allow HCX REST API traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL7"  {
  description = "Allow HCX cold migration traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL8"  {
  description = "Allow OVF import traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-HCX_SL9"  {
  description = "Allow HCX WAN transport traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-HCX.id
  protocol                  = "17"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "4500"
      min = "4500"
    }
  }
}
resource "oci_core_vlan" "VLAN-HCX" {
  availability_domain = var.ad
  cidr_block          = var.vlan_hcx_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-HCX"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-HCX.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-HCX.id
  vcn_id              = local.vcn_id
  vlan_tag            = "758"
}




# --------- vSphere VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-vSphere" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_vSphere_RT"
  vcn_id         = local.vcn_id
  route_rules {
    description       = "Allow NAT gateway traffic"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.natgw_id
  }
}
resource "oci_core_network_security_group" "NSG-for-vSphere" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-vSphere"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL3"  {
  description = "Allow NTP port traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "123"
      min = "123"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL4"  {
  description = "Allow SSH traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL5"  {
  description = "Allow traffic for NSX messaging channel to NSX Manager"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1234"
      min = "1234"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL6"  {
  description = "Allow traffic for vSAN Cluster Monitoring, Membership, and Directory Service"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "12345"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL7"  {
  description = "Allow Unicast agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL8"  {
  description = "Allow NestDB traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2480"
      min = "2480"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL9"  {
  description = "Allow iSCSI traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3260"
      min = "3260"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL10"  {
  description = "Allow BFD traffic between nodes"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL11"  {
  description = "Allow Edge HA traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "50263"
      min = "50263"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL12"  {
  description = "Allow NSX Agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5555"
      min = "5555"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL13"  {
  description = "Allow AMQP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5671"
      min = "5671"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL14"  {
  description = "Allow NSX messaging traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1235"
      min = "1234"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL15"  {
  description = "Allow HTTP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8080"
      min = "8080"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL16"  {
  description = "Allow RFB protocol traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5964"
      min = "5900"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL17"  {
  description = "Allow ESXi dump collector traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL18"  {
  description = "Allow ESXi dump collector traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL19"  {
  description = "Allow NSX Edge communication traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6666"
      min = "6666"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL20"  {
  description = "Allow NSX DLR traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6999"
      min = "6999"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL21"  {
  description = "Allow vSphere fault tolerance traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL22"  {
  description = "Allow vSphere fault tolerance traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL23"  {
  description = "Allow vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL24"  {
  description = "Allow vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL25"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8010"
      min = "8010"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL26"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL27"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL28"  {
  description = "Allow traffic to DVSSync port to enable fault tolerance"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8302"
      min = "8301"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL29"  {
  description = "Allow Web Services Management traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8889"
      min = "8889"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL30"  {
  description = "Allow Distributed Data Store traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL31"  {
  description = "Allow Distributed Data Store traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL32"  {
  description = "Allow vCenter Server to manage ESXi hosts"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL33"  {
  description = "Allow Server Agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL34"  {
  description = "Allow I/O Filter traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL35"  {
  description = "Allow RDT traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL36"  {
  description = "Allow CIM client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL37"  {
  description = "Allow CIM client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL38"  {
  description = "Allow HTTPS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL39"  {
  description = "Allow DNS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL40"  {
  description = "Allow DNS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL41"  {
  description = "Allow systemd-resolve traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "5355"
      min = "5355"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL42"  {
  description = "Allow appliance management traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5480"
      min = "5480"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL43"  {
  description = "Allow CIM traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5989"
      min = "5988"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL44"  {
  description = "Allow HTTP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL45"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL46"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL47"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-vSphere_SL48"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-vSphere.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
  }
}
resource "oci_core_vlan" "VLAN-vSphere" {
  availability_domain = var.ad
  cidr_block          = var.vlan_vsphere_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-vSphere"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-vSphere.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-vSphere.id
  vcn_id              = local.vcn_id
  vlan_tag            = "858"
}





# --------- Replication VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-Replication-Net" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_Replication_Net_RT"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group" "NSG-for-Replication-Net" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-Replication-Net"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL3"  {
  description = "SSH for VCHA replication and communication"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL4"  {
  description = "Ongoing replication traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "31031"
      min = "31031"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL5"  {
  description = "Ongoing replication traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "44046"
      min = "44046"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL6"  {
  description = "Monitoring and health pre-checks"
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "0"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL7"  {
  description = "Monitoring and health pre-checks"
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "8"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL8"  {
  description = "Traceroute diagnostic traffic"
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "0"
    type = "11"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL9"  {
  description = "Path MTU discovery traffic"
  destination_type = ""
  direction        = "INGRESS"
  icmp_options {
    code = "4"
    type = "3"
  }
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "1"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Replication-Net_SL10"  {
  description = "vSphere replication communication"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Replication-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
  }
}
resource "oci_core_vlan" "VLAN-Replication-Net" {
  availability_domain = var.ad
  cidr_block          = var.vlan_replication_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-Replication-Net"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-Replication-Net.id,
  ]
  route_table_id      = oci_core_route_table.Route-Table-for-Replication-Net.id
  vcn_id              = local.vcn_id
  vlan_tag            = "958"
}




# --------- Provisioning VLAN, NSG, Rules, RT
resource "oci_core_route_table" "Route-Table-for-Provisioning-Net" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_Provisioning_Net_RT"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group" "NSG-for-Provisioning-Net" {
  compartment_id = var.targetCompartment
  display_name   = "${local.sddc_name}_NSG-Provisioning-Net"
  vcn_id         = local.vcn_id
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL1"  {
  description               = "Allow all egress traffic"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "all"
  source_type = ""
  stateless   = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL2"  {
  description = "Allow all ingress from VCN CIDR"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "all"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL3"  {
  description = "Allow NTP port traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "123"
      min = "123"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL4"  {
  description = "Allow SSH traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL5"  {
  description = "Allow traffic for NSX messaging channel to NSX Manager"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1234"
      min = "1234"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL6"  {
  description = "Allow traffic for vSAN Cluster Monitoring, Membership, and Directory Service"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "23451"
      min = "12345"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL7"  {
  description = "Allow Unicast agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "12321"
      min = "12321"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL8"  {
  description = "Allow NestDB traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2480"
      min = "2480"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL9"  {
  description = "Allow iSCSI traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3260"
      min = "3260"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL10"  {
  description = "Allow BFD traffic between nodes"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "3785"
      min = "3784"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL11"  {
  description = "Allow Edge HA traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "50263"
      min = "50263"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL12"  {
  description = "Allow NSX Agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5555"
      min = "5555"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL13"  {
  description = "Allow AMQP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5671"
      min = "5671"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL14"  {
  description = "Allow NSX messaging traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "1235"
      min = "1234"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL15"  {
  description = "Allow HTTP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8080"
      min = "8080"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL16"  {
  description = "Allow RFB protocol traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5964"
      min = "5900"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL17"  {
  description = "Allow ESXi dump collector traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL18"  {
  description = "Allow ESXi dump collector traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "6500"
      min = "6500"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL19"  {
  description = "Allow NSX Edge communication traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6666"
      min = "6666"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL20"  {
  description = "Allow NSX DLR traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "6999"
      min = "6999"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL21"  {
  description = "Allow vSphere fault tolerance traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL22"  {
  description = "Allow vSphere fault tolerance traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8300"
      min = "8100"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL23"  {
  description = "Allow vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL24"  {
  description = "Allow vMotion traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8000"
      min = "8000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL25"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8010"
      min = "8010"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL26"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL27"  {
  description = "Allow vSAN health traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "8006"
      min = "8006"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL28"  {
  description = "Allow traffic to DVSSync port to enable fault tolerance"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8302"
      min = "8301"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL29"  {
  description = "Allow Web Services Management traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "8889"
      min = "8889"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL30"  {
  description = "Allow Distributed Data Store traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL31"  {
  description = "Allow Distributed Data Store traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9000"
      min = "9000"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL32"  {
  description = "Allow vCenter Server to manage ESXi hosts"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL33"  {
  description = "Allow Server Agent traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "902"
      min = "902"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL34"  {
  description = "Allow I/O Filter traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9080"
      min = "9080"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL35"  {
  description = "Allow RDT traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "2233"
      min = "2233"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL36"  {
  description = "Allow CIM client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL37"  {
  description = "Allow CIM client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "427"
      min = "427"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL38"  {
  description = "Allow HTTPS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "443"
      min = "443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL39"  {
  description = "Allow DNS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL40"  {
  description = "Allow DNS traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "53"
      min = "53"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL41"  {
  description = "Allow systemd-resolve traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "5355"
      min = "5355"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL42"  {
  description = "Allow appliance management traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5480"
      min = "5480"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL43"  {
  description = "Allow CIM traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "5989"
      min = "5988"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL44"  {
  description = "Allow HTTP traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL45"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL46"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9090"
      min = "9090"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL47"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "6"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  tcp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
  }
}
resource "oci_core_network_security_group_security_rule" "NSG-for-Provisioning-Net_SL48"  {
  description = "Allow vSphere Web Client traffic"
  destination_type          = ""
  direction                 = "INGRESS"
  network_security_group_id = oci_core_network_security_group.NSG-for-Provisioning-Net.id
  protocol                  = "17"
  source                    = data.oci_core_vcn.vcn.cidr_block
  source_type               = "CIDR_BLOCK"
  stateless                 = "false"
  udp_options {
    destination_port_range {
      max = "9443"
      min = "9443"
    }
  }
}
resource "oci_core_vlan" "VLAN-Provisioning-Net" {
  availability_domain = var.ad
  cidr_block          = var.vlan_provisioning_cidr
  compartment_id      = var.targetCompartment
  display_name        = "${local.sddc_name}_VLAN-Provisioning-Net"
  nsg_ids = [
    oci_core_network_security_group.NSG-for-Provisioning-Net.id,
  ]
  route_table_id = oci_core_route_table.Route-Table-for-Provisioning-Net.id
  vcn_id         = local.vcn_id
  vlan_tag       = "1058"
}



# --------- SDDC --------- 
resource "oci_ocvp_sddc" "sddc" {
  depends_on                   = [oci_core_instance.bastion,null_resource.bastion,oci_core_instance.jumphost]
  display_name   	       = "${local.sddc_name}-sddc"
  compartment_id 	       = var.targetCompartment
  compute_availability_domain  = var.ad
  esxi_hosts_count             = local.esxi_host_count
  vmware_software_version      = var.vmware_software_version
  is_hcx_enabled               = var.is_hcx_enabled
  is_single_host_sddc          = var.is_single_host_sddc
  is_shielded_instance_enabled = var.is_shielded_instance_enabled
  workload_network_cidr        = var.sddc_workload_cidr
  initial_sku                  = var.sddc_initial_sku
  initial_host_shape_name      = var.esxi_host_shape
  initial_host_ocpu_count      = local.esxi_host_ocpus
  ssh_authorized_keys          = var.ssh_key

  provisioning_subnet_id       = oci_core_subnet.provisioning-subnet.id 
  nsx_edge_uplink1vlan_id      = oci_core_vlan.VLAN-NSX-Edge-Uplink-1.id
  nsx_edge_uplink2vlan_id      = oci_core_vlan.VLAN-NSX-Edge-Uplink-2.id
  nsx_edge_vtep_vlan_id        = oci_core_vlan.VLAN-NSX-Edge-VTEP.id
  nsx_vtep_vlan_id             = oci_core_vlan.VLAN-NSX-VTEP.id
  vmotion_vlan_id              = oci_core_vlan.VLAN-vMotion.id
  vsan_vlan_id                 = oci_core_vlan.VLAN-vSAN.id
  hcx_vlan_id                  = oci_core_vlan.VLAN-HCX.id
  vsphere_vlan_id              = oci_core_vlan.VLAN-vSphere.id
  replication_vlan_id          = oci_core_vlan.VLAN-Replication-Net.id
  provisioning_vlan_id         = oci_core_vlan.VLAN-Provisioning-Net.id

}