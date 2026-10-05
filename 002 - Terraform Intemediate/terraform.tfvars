env          = "prod"
region       = "canadacentral"
sub_id       = "<enterID>"
subnet_count = 3

subnets = {
  general = {
    subnet_position = 0 # 10.60.0.0/16
  }
  mysql = {
    subnet_position                 = 1 # 10.60.1.0/16
    delegation                      = "Microsoft.DBforMySQL/flexibleServers"
    default_outbound_access_enabled = false
  }
  appservice = {
    subnet_position = 2 # 10.60.2.0/16
    delegation      = "Microsoft.Web/serverFarms"
  }
  storage = {
    subnet_position = 3
  }
}

mandatory_tags = {
  owner1      = "<enterUPN>"
  owner2      = "<enterUPN>"
  cost-centre = "1001"
}