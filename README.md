# Nomad AWS Module

This is a Terraform module for provisioning a Nomad Cluster on AWS. This cluster
utilizes [Consul](https://www.consul.io/) as recommended by the [Nomad Reference
Architecture](https://www.nomadproject.io/docs/install/production/reference-architecture#ra).
The default is set to 5 servers and 3 clients.

## How to Use This Module

- Create a Terraform configuration that pulls in the module and specifies values
  of the required variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
}

provider "random" {
  version = "~> 2.2"
}

module "nomad_cluster" {
  source = "git@github.com:hashicorp/terraform-aws-nomad-espd.git"

  vpc_id         = "<your VPC id>"
  consul_version = "<consul version (ex: 1.7.4)>"
  nomad_version  = "<nomad version (ex: 0.11.3)>"
  owner          = "<owner name/tag>"
  name_prefix    = "<name prefix you would like attached to your environment>"
  key_name       = "<your SSH key>"
  nomad_servers  = 5
  nomad_clients  = 3
}
```

Note: Currently the random provider is required for this module's functionality.

- If you want to use a certain release of the module, specify the `ref` tag in
  your source option as shown below:

```hcl

provider "aws" {
  region = "<your AWS region>"
}

provider "random" {
  version = "~> 2.2"
}

module "nomad_cluster" {
  source = "git@github.com:hashicorp/terraform-aws-nomad-espd.git?ref=v0.0.1"

  vpc_id         = "<your VPC id>"
  consul_version = "<consul version (ex: 1.7.4)>"
  nomad_version  = "<nomad version (ex: 0.11.3)>"
  owner          = "<owner name/tag>"
  name_prefix    = "<name prefix you would like attached to your environment>"
  key_name       = "<your SSH key>"
  nomad_servers  = 5
  nomad_clients  = 3
}
```

- Run `terraform init` and `terraform apply`
