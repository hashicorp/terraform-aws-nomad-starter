#!/usr/bin/env bash

# install package

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y consul=${consul_version}
apt-get install -y nomad=${nomad_version}
apt-get install -y docker.io

echo "Configuring system time"
timedatectl set-timezone UTC

echo "Starting deployment from AMI: ${ami}"
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
AVAILABILITY_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
LOCAL_IPV4=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

cat << EOF > /etc/consul.d/consul.hcl
datacenter          = "${datacenter}"
server              = false
data_dir            = "/opt/consul/data"
advertise_addr      = "$${LOCAL_IPV4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
encrypt             = "${gossip_key}"

# AWS cloud join
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
EOF

chown -R consul:consul /etc/consul.d
chmod -R 640 /etc/consul.d/*

systemctl daemon-reload
systemctl enable consul
systemctl start consul

cat << EOF > /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

# Enable the client
client {
  enabled = true
}

consul {
  address = "127.0.0.1:8500"
  token   = "${master_token}"
}
EOF

chown -R nomad:nomad /etc/nomad.d
chmod -R 640 /etc/nomad.d/*

systemctl enable nomad
systemctl start nomad
