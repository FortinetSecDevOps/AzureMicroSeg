//############################ Create Resource Group ##################

resource "azurerm_resource_group" "RG" {
  name     = "${var.TAG}-${var.project}"
  location = var.vnetloc
}


//############################ Create VNETs  ##################

resource "azurerm_virtual_network" "vnetperftest" {
  name                =   "${var.TAG}-${var.project}-vnet-${var.vnetloc}"
  location            =   var.vnetloc
  resource_group_name =   azurerm_resource_group.RG.name
  address_space       =   var.vnetcidr 
  
  tags = {
    Project = "${var.project}"
  }
}

//############################ Create VNET Subnets ##################

resource "azurerm_subnet" "vnetsubnets" {
  for_each = var.vnetsubnets 

  name                =   "${var.TAG}-${var.project}-subnet-${each.value.name}"
  resource_group_name =   azurerm_resource_group.RG.name
  address_prefixes    =   [ each.value.cidr ]
  virtual_network_name = azurerm_virtual_network.vnetperftest.name

}


//############################ Create RTB Hub1 ##################
resource "azurerm_route_table" "vnet_fgt_pub_RTB" {
  name                          = "${var.TAG}-${var.project}-fgt-pub_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

resource "azurerm_subnet_route_table_association" "vnet_pub_RTB_assoc" {
  subnet_id      =  element([for subid in azurerm_subnet.vnetsubnets: subid.id] , 0 )
  route_table_id = azurerm_route_table.vnet_fgt_pub_RTB.id
} 

resource "azurerm_route" "vnet_fgt_pub_RTB_default" {
  name                = "defaultInternet"
  resource_group_name   =  azurerm_resource_group.RG.name
  route_table_name      = azurerm_route_table.vnet_fgt_pub_RTB.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

///////////////// Priv
resource "azurerm_route_table" "vnet_fgt_priv_RTB" {
  name                          = "${var.TAG}-${var.project}-fgt-priv_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

///////////////// K8s Nodes RTB
resource "azurerm_route_table" "vnet_k8s_node_RTB" {
  name                          = "${var.TAG}-${var.project}-k8s_nodes_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

resource "azurerm_route" "vnet_k8s_node_RTB_route1" {
  name                  =   "default"
  resource_group_name   =   azurerm_resource_group.RG.name
  route_table_name      =   azurerm_route_table.vnet_k8s_node_RTB.name
  address_prefix        = "0.0.0.0/0"
  next_hop_type         = "VirtualAppliance"
  next_hop_in_ip_address = element ( values(var.dut1)[*].ip , 0 )
}