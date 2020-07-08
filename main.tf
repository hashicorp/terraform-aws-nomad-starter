module "nomad_cluster" {
  source = "./modules/nomad_cluster"

  allowed_inbound_cidrs  = var.allowed_inbound_cidrs
  instance_type          = var.instance_type
  consul_version         = var.consul_version
  nomad_version          = var.nomad_version
  consul_cluster_version = var.consul_cluster_version
  bootstrap              = var.bootstrap
  key_name               = var.key_name
  name_prefix            = var.name_prefix
  vpc_id                 = var.vpc_id
  public_ip              = var.public_ip
  nomad_servers          = var.nomad_servers
  nomad_clients          = var.nomad_clients
  consul_config          = var.consul_config
  enable_connect         = var.enable_connect
  owner                  = var.owner
}
