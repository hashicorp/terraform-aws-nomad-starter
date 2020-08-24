#!/usr/bin/env bash

# install package

curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update
apt-get install -y consul=${consul_version}
apt-get install -y nomad=${nomad_version}

echo "Installing jq"
curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x /bin/jq

echo "Configuring system time"
timedatectl set-timezone UTC

echo "Starting deployment from AMI: ${ami}"
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
AVAILABILITY_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
LOCAL_IPV4=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`

cat << EOF > /etc/consul.d/consul.hcl
datacenter          = "${datacenter}"
server              = true
bootstrap_expect    = ${bootstrap_expect}
data_dir            = "/opt/consul/data"
advertise_addr      = "$${LOCAL_IPV4}"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true

# AWS cloud join
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]

# Max connections for the HTTP API
limits {
  http_max_conns_per_client = 128
}
performance {
    raft_multiplier = 1
}

acl {
  enabled        = true
  %{ if bootstrap }default_policy = "allow"%{ else }default_policy = "deny"%{ endif }
  enable_token_persistence = true
  tokens {
    master = "${master_token}"%{ if !bootstrap }
    agent  = "${agent_server_token}"%{ endif }
  }
}

encrypt = "${gossip_key}"
EOF

cat << EOF > /etc/consul.d/autopilot.hcl
autopilot {
  upgrade_version_tag = "consul_cluster_version"
}
EOF

cat << EOF > /etc/consul.d/cluster_version.hcl
node_meta = {
    consul_cluster_version = "${consul_cluster_version}"
}
EOF

%{ if enable_connect }
cat << EOF > /etc/consul.d/connect.hcl
connect {
  enabled = true
}
EOF
%{ endif }

%{ if consul_config != {} }
cat << EOF > /etc/consul.d/zz-override.json
${jsonencode(consul_config)}
EOF
%{ endif }


%{ if bootstrap }
cat << EOF > /tmp/bootstrap_tokens.sh
#!/bin/bash
export CONSUL_HTTP_TOKEN=${master_token}
echo "Creating Consul ACL policies......"
if ! consul kv get acl_bootstrap 2>/dev/null; then
  consul kv put  acl_bootstrap 1

  echo '
  node_prefix "" {
    policy = "write"
  }
  service_prefix "" {
    policy = "read"
  }
  service "consul" {
    policy = "write"
  }
  agent_prefix "" {
    policy = "write"
  }' | consul acl policy create -name consul-agent-server -rules -

  # echo '
  # acl = "write"
  # key "consul-snapshot/lock" {
  # policy = "write"
  # }
  # session_prefix "" {
  # policy = "write"
  # }
  # service "consul-snapshot" {
  # policy = "write"
  # }' | consul acl policy create -name snapshot_agent -rules -

  echo '
  node_prefix "" {
    policy = "read"
  }
  service_prefix "" {
    policy = "read"
  }
  session_prefix "" {
    policy = "read"
  }
  agent_prefix "" {
    policy = "read"
  }
  query_prefix "" {
    policy = "read"
  }
  operator = "read"' |  consul acl policy create -name anonymous -rules -

  consul acl token create -description "consul agent server token" -policy-name consul-agent-server -secret "${agent_server_token}" 1>/dev/null
  # consul acl token create -description "consul snapshot agent" -policy-name snapshot_agent -secret "${snapshot_token}" 1>/dev/null
  consul acl token update -id anonymous -policy-name anonymous 1>/dev/null
else
  echo "Bootstrap already completed"
fi
EOF

chmod 700 /tmp/bootstrap_tokens.sh

%{ endif }

chown -R consul:consul /etc/consul.d
chmod -R 640 /etc/consul.d/*

systemctl daemon-reload
systemctl enable consul
systemctl start consul

# Wait for consul-kv to come online
while true; do
    curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -e . && break
    sleep 5
done

# Wait until all new node versions are online
until [[ $TOTAL_NEW -ge ${total_nodes} ]]; do
    TOTAL_NEW=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er 'map(select(.NodeMeta.consul_cluster_version == "${consul_cluster_version}")) | length'`
    sleep 5
    echo "Current New Node Count: $TOTAL_NEW"
done

# Wait for a leader
until [[ $LEADER -eq 1 ]]; do
    let LEADER=0
    echo "Fetching new node ID's"
    NEW_NODE_IDS=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -r 'map(select(.NodeMeta.consul_cluster_version == "${consul_cluster_version}")) | .[].ID'`
    # Wait until all new nodes are voting
    until [[ $VOTERS -eq ${bootstrap_expect} ]]; do
        let VOTERS=0
        for ID in $NEW_NODE_IDS; do
            echo "Checking $ID"
            curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -e ".Servers[] | select(.ID == \"$ID\" and .Voter == true)" && let "VOTERS+=1" && echo "Current Voters: $VOTERS"
            sleep 2
        done
    done
    echo "Checking Old Nodes"
    OLD_NODES=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | length'`
    echo "Current Old Node Count: $OLD_NODES"
    # Wait for old nodes to drop from voting
    until [[ $OLD_NODES -eq 0 ]]; do
        OLD_NODES=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | length'`
        OLD_NODE_IDS=`curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -r 'map(select(.NodeMeta.consul_cluster_version != "${consul_cluster_version}")) | .[].ID'`
        for ID in $OLD_NODE_IDS; do
            echo "Checking Old $ID"
            curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -e ".Servers[] | select(.ID == \"$ID\" and .Voter == false)" && let "OLD_NODES-=1" && echo "Checking Old Nodes for Voters: $OLD_NODES"
            sleep 2
        done
    done
    # Check if there is a leader running the newest version
    LEADER_ID=`curl -s http://127.0.0.1:8500/v1/operator/autopilot/health | jq -er ".Servers[] | select(.Leader == true) | .ID"`
    curl -s http://127.0.0.1:8500/v1/catalog/service/consul | jq -er ".[] | select(.ID == \"$LEADER_ID\" and .NodeMeta.consul_cluster_version == \"${consul_cluster_version}\")" && let "LEADER+=1" && echo "New Leader: $LEADER_ID"
    sleep 2
done

%{ if bootstrap }/tmp/bootstrap_tokens.sh%{ endif }
echo "$INSTANCE_ID determined all nodes to be healthy and ready to go <3"

cat << EOF > /etc/nomad.d/nomad.hcl
data_dir = "/opt/nomad/data"
bind_addr = "0.0.0.0"

# Enable the server
server {
  enabled = true
  bootstrap_expect = ${bootstrap_expect}
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
