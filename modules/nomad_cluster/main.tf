# data source for current (working) aws region
data "aws_region" "current" {}

# data source for VPC id for the VPC being used
data "aws_vpc" "nomad_vpc" {
  id = var.vpc_id
}

# data source for subnet ids in VPC
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.nomad_vpc.id
}

# data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# data source for vanilla Ubuntu AWS AMI as base image for cluster
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# creates random UUID for the environment name
resource "random_id" "environment_name" {
  byte_length = 4
  prefix      = "${var.name_prefix}-"
}

# creates Nomad autoscaling group for servers
resource "aws_autoscaling_group" "nomad_servers" {
  name                      = aws_launch_configuration.nomad_servers.name
  launch_configuration      = aws_launch_configuration.nomad_servers.name
  availability_zones        = data.aws_availability_zones.available.zone_ids
  min_size                  = var.nomad_servers
  max_size                  = var.nomad_servers
  desired_capacity          = var.nomad_servers
  wait_for_capacity_timeout = "480s"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.aws_subnet_ids.default.ids
  tags = [
    {
      key                 = "Name"
      value               = "${var.name_prefix}-nomad-server"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster-Version"
      value               = var.consul_cluster_version
      propagate_at_launch = true
    },
    {
      key                 = "Environment-Name"
      value               = "${var.name_prefix}-nomad"
      propagate_at_launch = true
    },
    {
      key                 = "owner"
      value               = var.owner
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# provides a resource for a new autoscaling group launch configuration
resource "aws_launch_configuration" "nomad_servers" {
  name            = "${random_id.environment_name.hex}-nomad-servers-${var.consul_cluster_version}"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.nomad.id]
  user_data = templatefile("${path.module}/scripts/install_hashitools_nomad_server.sh.tpl",
    {
      ami                    = data.aws_ami.ubuntu.id,
      environment_name       = "${var.name_prefix}-nomad",
      consul_version         = var.consul_version,
      nomad_version          = var.nomad_version,
      datacenter             = data.aws_region.current.name,
      bootstrap_expect       = var.nomad_servers,
      total_nodes            = var.nomad_servers,
      gossip_key             = random_id.consul_gossip_encryption_key.b64_std,
      master_token           = random_uuid.consul_master_token.result,
      agent_server_token     = random_uuid.consul_agent_server_token.result,
      snapshot_token         = random_uuid.consul_snapshot_token.result,
      consul_cluster_version = var.consul_cluster_version,
      bootstrap              = var.bootstrap,
      enable_connect         = var.enable_connect,
      consul_config          = var.consul_config,
  })
  associate_public_ip_address = var.public_ip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  root_block_device {
    volume_type = "io1"
    volume_size = 50
    iops        = "2500"
  }

  lifecycle {
    create_before_destroy = true
  }
}
