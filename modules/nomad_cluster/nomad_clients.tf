# creates Nomad autoscaling group for clients
resource "aws_autoscaling_group" "nomad_clients" {
  name                      = aws_launch_configuration.nomad_clients.name
  launch_configuration      = aws_launch_configuration.nomad_clients.name
  availability_zones        = data.aws_availability_zones.available.zone_ids
  min_size                  = var.nomad_clients
  max_size                  = var.nomad_clients
  desired_capacity          = var.nomad_clients
  wait_for_capacity_timeout = "480s"
  health_check_grace_period = 15
  health_check_type         = "EC2"
  vpc_zone_identifier       = data.aws_subnet_ids.default.ids

  tags = [
    {
      key                 = "Name"
      value               = "${var.name_prefix}-nomad-client"
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

  depends_on = [aws_autoscaling_group.nomad_servers]

  lifecycle {
    create_before_destroy = true
  }
}

# provides a resource for a new autoscaling group launch configuration
resource "aws_launch_configuration" "nomad_clients" {
  name            = "${random_id.environment_name.hex}-nomad-clients-${var.consul_cluster_version}"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.nomad.id]
  user_data = templatefile("${path.module}/scripts/install_hashitools_nomad_client.sh.tpl",
    {
      ami              = data.aws_ami.ubuntu.id,
      environment_name = "${var.name_prefix}-nomad",
      consul_version   = var.consul_version,
      nomad_version    = var.nomad_version,
      datacenter       = data.aws_region.current.name,
      gossip_key       = random_id.consul_gossip_encryption_key.b64_std,
      master_token     = random_uuid.consul_master_token.result
  })
  associate_public_ip_address = var.public_ip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  root_block_device {
    volume_size = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}
