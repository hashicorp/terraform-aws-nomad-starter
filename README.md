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
  specifies values of the required variables. You may use the contents of the
  [`main.tf`](main.tf) file as your module definition if adding this to your
  existing infrastructure by changing the source of the module definition.

  ```hcl
  module "nomad_cluster" {
    source = "hashicorp/nomad-starter/aws"
    version = "0.2.1"
    ... <snip>
  }
  ```

- `version`: The Nomad AWS [module
  version](https://registry.terraform.io/modules/hashicorp/nomad-starter/aws/latest)
  to pull (e.g. `0.2.1`) during the initialization
- `allowed_inbound_cidrs`: Allowed CIDR blocks for SSH and API/UI access. You can find your public IP from [whatismyip](https://www.whatsmyip.org/). (e.g. The value for this would look like `"1.1.1.1/32"`)
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