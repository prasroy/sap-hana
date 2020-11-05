/*
  Description:
  Setup common infrastructure
*/

module "common_infrastructure" {
  source              = "../../terraform-units/modules/sap_system/common_infrastructure"
  is_single_node_hana = "true"
  application         = var.application
  databases           = var.databases
  infrastructure      = var.infrastructure
  jumpboxes           = var.jumpboxes
  options             = local.options
  software            = var.software
  ssh-timeout         = var.ssh-timeout
  sshkey              = var.sshkey
  naming              = module.sap_namegenerator.naming
  service_principal   = local.service_principal
  deployer_tfstate    = data.terraform_remote_state.deployer.outputs
  // Comment out code with users.object_id for the time being.
  // deployer_user       = module.deployer.deployer_user
}

module "sap_namegenerator" {
  source        = "../../terraform-units/modules/sap_namegenerator"
  environment   = var.infrastructure.environment
  location      = var.infrastructure.region
  codename      = lower(try(var.infrastructure.codename, ""))
  random_id     = module.common_infrastructure.random_id
  sap_vnet_name = local.vnet_sap_name_part
  sap_sid       = local.sap_sid
  db_sid        = local.db_sid
  app_ostype    = local.app_ostype
  anchor_ostype = local.anchor_ostype
  db_ostype     = local.db_ostype
  /////////////////////////////////////////////////////////////////////////////////////
  // The naming module creates a list of servers names that is app_server_count
  // for database servers the list is 2 * db_server_count. 
  // The first db_server_count items are for single node
  // The the second db_server_count items are for ha
  /////////////////////////////////////////////////////////////////////////////////////
  db_server_count  = local.db_server_count
  app_server_count = local.app_server_count
  web_server_count = local.webdispatcher_count
  scs_server_count = local.scs_server_count
  app_zones        = local.app_zones
  scs_zones        = local.scs_zones
  web_zones        = local.web_zones
  db_zones         = local.db_zones
}

// Create Jumpboxes
module "jumpbox" {
  source            = "../../terraform-units/modules/sap_system/jumpbox"
  application       = var.application
  databases         = var.databases
  infrastructure    = var.infrastructure
  jumpboxes         = var.jumpboxes
  options           = local.options
  software          = var.software
  ssh-timeout       = var.ssh-timeout
  sshkey            = var.sshkey
  resource_group    = module.common_infrastructure.resource_group
  storage_bootdiag  = module.common_infrastructure.storage_bootdiag
  output_json       = module.output_files.output_json
  ansible_inventory = module.output_files.ansible_inventory
  random_id         = module.common_infrastructure.random_id
  deployer_tfstate  = data.terraform_remote_state.deployer.outputs
}

// Create HANA database nodes
module "hdb_node" {
  source           = "../../terraform-units/modules/sap_system/hdb_node"
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = local.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource_group   = module.common_infrastructure.resource_group
  vnet_sap         = module.common_infrastructure.vnet_sap
  storage_bootdiag = module.common_infrastructure.storage_bootdiag
  ppg              = module.common_infrastructure.ppg
  sid_kv_user      = module.common_infrastructure.sid_kv_user
  // Comment out code with users.object_id for the time being.
  // deployer_user    = module.deployer.deployer_user
  naming                     = module.sap_namegenerator.naming
  custom_disk_sizes_filename = var.db_disk_sizes_filename
  admin_subnet               = module.common_infrastructure.admin_subnet
}

// Create Application Tier nodes
module "app_tier" {
  source           = "../../terraform-units/modules/sap_system/app_tier"
  application      = var.application
  databases        = var.databases
  infrastructure   = var.infrastructure
  jumpboxes        = var.jumpboxes
  options          = local.options
  software         = var.software
  ssh-timeout      = var.ssh-timeout
  sshkey           = var.sshkey
  resource_group   = module.common_infrastructure.resource_group
  vnet_sap         = module.common_infrastructure.vnet_sap
  storage_bootdiag = module.common_infrastructure.storage_bootdiag
  ppg              = module.common_infrastructure.ppg
  sid_kv_user      = module.common_infrastructure.sid_kv_user
  // Comment out code with users.object_id for the time being.  
  // deployer_user    = module.deployer.deployer_user
  naming                     = module.sap_namegenerator.naming
  admin_subnet               = module.common_infrastructure.admin_subnet
  custom_disk_sizes_filename = var.app_disk_sizes_filename
}

// Create anydb database nodes
module "anydb_node" {
  source                     = "../../terraform-units/modules/sap_system/anydb_node"
  application                = var.application
  databases                  = var.databases
  infrastructure             = var.infrastructure
  jumpboxes                  = var.jumpboxes
  options                    = var.options
  software                   = var.software
  ssh-timeout                = var.ssh-timeout
  sshkey                     = var.sshkey
  resource_group             = module.common_infrastructure.resource_group
  vnet_sap                   = module.common_infrastructure.vnet_sap
  storage_bootdiag           = module.common_infrastructure.storage_bootdiag
  ppg                        = module.common_infrastructure.ppg
  sid_kv_user                = module.common_infrastructure.sid_kv_user
  naming                     = module.sap_namegenerator.naming
  custom_disk_sizes_filename = var.db_disk_sizes_filename
  admin_subnet               = module.common_infrastructure.admin_subnet
}

// Generate output files
module "output_files" {
  source                       = "../../terraform-units/modules/sap_system/output_files"
  application                  = module.app_tier.application
  databases                    = var.databases
  infrastructure               = var.infrastructure
  jumpboxes                    = var.jumpboxes
  options                      = local.options
  software                     = var.software
  ssh-timeout                  = var.ssh-timeout
  sshkey                       = var.sshkey
  nics_iscsi                   = module.common_infrastructure.nics_iscsi
  infrastructure_w_defaults    = module.common_infrastructure.infrastructure_w_defaults
  software_w_defaults          = module.common_infrastructure.software_w_defaults
  nics_jumpboxes_windows       = module.jumpbox.nics_jumpboxes_windows
  nics_jumpboxes_linux         = module.jumpbox.nics_jumpboxes_linux
  public_ips_jumpboxes_windows = module.jumpbox.public_ips_jumpboxes_windows
  public_ips_jumpboxes_linux   = module.jumpbox.public_ips_jumpboxes_linux
  jumpboxes_linux              = module.jumpbox.jumpboxes_linux
  nics_dbnodes_admin           = module.hdb_node.nics_dbnodes_admin
  nics_dbnodes_db              = module.hdb_node.nics_dbnodes_db
  loadbalancers                = module.hdb_node.loadbalancers
  hdb_sid                      = module.hdb_node.hdb_sid
  hana_database_info           = module.hdb_node.hana_database_info
  nics_scs                     = module.app_tier.nics_scs
  nics_app                     = module.app_tier.nics_app
  nics_web                     = module.app_tier.nics_web
  nics_anydb                   = module.anydb_node.nics_anydb
  nics_scs_admin               = module.app_tier.nics_scs_admin
  nics_app_admin               = module.app_tier.nics_app_admin
  nics_web_admin               = module.app_tier.nics_web_admin
  nics_anydb_admin             = module.anydb_node.nics_anydb_admin
  any_database_info            = module.anydb_node.any_database_info
  anydb_loadbalancers          = module.anydb_node.anydb_loadbalancers
  random_id                    = module.common_infrastructure.random_id
}