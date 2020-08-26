# Nomad AWS Module

This is a Terraform module for provisioning a Nomad Cluster on AWS. This cluster
utilizes [Consul](https://www.consul.io/) as recommended by the [Nomad Reference
Architecture](https://www.nomadproject.io/docs/install/production/reference-architecture#ra).
The default is set to 5 servers and 3 clients.

## About This Module

This module implements the [Nomad Reference Architecture](https://www.nomadproject.io/docs/install/production/reference-architecture#ra). It is created and maintained by HashiCorp to exist as a canonical implementation of a Nomad cluster in the Amazon Web Services cloud, and enforces this prescriptive methodology through the use of default values corresponding to the recommendations of our Enterprise Architects.

For more advanced practitioners requiring  a wider variety of configurable options, please see [Terraform AWS Nomad Module](https://registry.terraform.io/modules/hashicorp/nomad/aws/0.6.3).

## How to Use This Module

- Create a Terraform configuration (`main.tf`) that pulls in the module and
  specifies values of the required variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
}

module "nomad-oss" {
  source                = "hashicorp/nomad-oss/aws"
  version               = "<module version>"
  allowed_inbound_cidrs = ["<list of inbound CIDRs>"]
  vpc_id                = "<your VPC id>"
  consul_version        = "<consul version (ex: 1.8.3)>"
  nomad_version         = "<nomad version (ex: 0.12.3)>"
  owner                 = "<owner name/tag>"
  name_prefix           = "<name prefix you would like attached to your environment>"
  key_name              = "<your SSH key name>"
  nomad_servers         = 5
  nomad_clients         = 3
}
```
- `version`: The Nomad AWS [module
  version](https://registry.terraform.io/modules/hashicorp/nomad-oss/aws/0.2.1)
  to pull (e.g. `0.2.1`) during the initialization
- `allowed_inbound_cidrs`: Allowed CIDR blocks for SSH and API/UI access
- `vpc_id`: ID of the VPC where cloud resources to be provisioned
- `consul_version`: Desired [Consul
  version](https://releases.hashicorp.com/consul/) to install
- `nomad_version`: Desired [Nomad
  version](https://releases.hashicorp.com/nomad/) to install
- `key_name`: The name of the SSH [key
  pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#prepare-key-pair)
  to use. This must exist in the specified AWS `region`

Run `terraform init` and `terraform apply` to provision a Nomad cluster.


## License

This code is released under the MPL 2.0 License. Please see
[LICENSE](https://github.com/hashicorp/terraform-aws-nomad-oss/blob/master/LICENSE)
for more details.