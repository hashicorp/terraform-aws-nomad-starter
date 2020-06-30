# Nomad AWS Module

This is a Terraform module for provisioning a Nomad Cluster on AWS. This cluster
utilizes [Consul](https://www.consul.io/) as recommended by the [Nomad Reference
Architecture](https://www.nomadproject.io/docs/install/production/reference-architecture#ra).
The default is set to 5 servers and 3 clients.

## About This Module

This module implements the [Nomad Reference Architecture](https://www.nomadproject.io/docs/install/production/reference-architecture#ra). It is created and maintained by HashiCorp to exist as a canonical implementation of a Nomad cluster in the Amazon Web Services cloud, and enforces this prescriptive methodology through the use of default values corresponding to the recommendations of our Enterprise Architects.

For more advanced practitioners requiring  a wider variety of configurable options, please see [Terraform AWS Nomad Module](https://registry.terraform.io/modules/hashicorp/nomad/aws/0.6.3).

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
  source = "https://github.com/hashicorp/terraform-aws-nomad-oss"

  vpc_id         = "<your VPC id>"
  consul_version = "<consul version (ex: 1.7.4)>"
  nomad_version  = "<nomad version (ex: 0.11.3)>"
  owner          = "<owner name/tag>"
  name_prefix    = "<name prefix you would like attached to your environment>"
  key_name       = "<your SSH key name>"
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
  source = "https://github.com/hashicorp/terraform-aws-nomad-oss?ref=v0.1.0"

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


## License

This code is released under the MPL 2.0 License. Please see [LICENSE](./LICENSE) for more details.
