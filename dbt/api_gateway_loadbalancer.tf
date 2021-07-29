locals {
  loadbalancers = !var.create_loadbalancer ? {} : {
    api-gateway-loadbalancer = {
      port = 8000
      selector = {
        name = "api-gateway"
      }
      create_alias_record = var.create_alias_record
      alias_domain_name = var.alias_domain_name
    }
  }
}