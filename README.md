# terraform-aws-dbt-cloud-single-tenant

## Bootstrapping steps

The following steps are required prior to creating the dbt Cloud infrastructure in AWS using terraform.

### Creating an AWS Profile

To connect to the aws account run `aws configure --profile <PROFILE_NAME>` and enter valid AWS secret values for an IAM user in the account where you will be installing the dbt Cloud application. After running the above command, make sure that the current AWS profile is set by running `export AWS_PROFILE=<PROFILE_NAME>` (for Mac users) or `setx AWS_PROFILE <PROFILE_NAME>` (for Windows users). Note that this profile will be needed later when setting the Kubernetes context after infrastructure is configured.

### Terraform Creator IAM Role Creation

It is highly recommended that the environment infrastructure be created by assuming an IAM role in the AWS host account rather than by an IAM user. This can prevent loss of access to certain components, specifically in EKS (see [here](https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/iam-permissions.md) for information in EKS specific IAM permissions), if a user leaves an organization. The TFCreator role should be granted the AdministratorAccess policy and set up with the following Trust relationship.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::<ACCOUNT_ID>:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Once created the role arn should be entered in the "creation_role_arn" variable in the `vars.tf` file for each environment directory. The role is assumed by Terraform in the aws provider for each environment. Note that this role will be needed again when installing dbt Cloud.

### VPC Creation

The infrastructure needed to host the dbt Cloud application in AWS must live in a VPC configured outside of this module. Examples of how to create such a VPC using Terraform can be seen in either the custom or standard examples in this module.

### Domain Name Setup

In order to host the dbt Cloud application, a valid domain name must be set in the `domain_name` variable in the (root)/vars file and each of the "hosted_zone_name" fields in the respective environment declarations of the single_tenant module. This domain name should either be established in the corresponding AWS account for the deployment, or appropriate DNS records should be created to forward traffic to the URL if the domain is managed in a separate account.

Note: When running `terraform apply` for the first time, the module may fail to validate the ACM certificate as this uses [DNS to validate domain ownvership](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html). If it fails, wait for the ACM certificate to become validated by AWS by monitoring the Admin Console and re-run `terraform apply` once validated.

## Configuration Process

After creating the infrastructure by running `terraform apply` the following steps must be run to configure the infrastructure for the dbt Cloud application.

## dbt Cloud Installation Process

After the environment configuration is complete the dbt Cloud application can be configured and installed via the Replicated (KOTS) admin console. If the optional 'create_admin_console_script' variable was set to true then a script and corresponding config file will be created to automatically install the KOTS admin console will pre-filled values populated from other related optional variables and the infrastructure build by Terraform (such as RDS hostname). This script can simply by ran from the shell with `./dbt_config.sh`. Once the admin console is installed it can be accessed via localhost:8800. After entering the password and a valid license, the deployment engineer will be redirected to the config page with all values prepopulated. These values should be double checked before continuing to deploy the latest channel version of dbt Cloud.

If the `create_admin_console_script` variable was not set to true, the KOTS admin console can be manually configured using the following steps below.

### Setting up the Kubernetes context

The above environment configuration process will have created an EKS cluster with a naming convention `<namespace>-<environment`. To connect to the cluster run the following command using the 'AWS profile' and 'TF Creator role arn' created in the bootstrapping section:

`aws eks update-kubeconfig --profile <AWS_PROFILE_NAME> --name <EKS_CLUSTER_NAME> --role-arn <TF_CREATOR_ROLE_ARN>`

Once the kubeconfig is successfully updated, the namespaces on the cluster can be viewed by running `kubectl get ns`. The environment configuration process will have generated a namespace wilt the following syntax: `dbt-cloud-<namespace>-<environment>`. This namespace will be needed for the next step.

### Installing the kots admin console

Once connected to the desired cluster, the Replicated kots administration console can be installed. First determine the  by running the below commands. Note that `dbt-cloud-<account>-<environment>` namespace from the above step needs to be passed to the `kubectl kots install` command, as otherwise the command will prompt to enter a new namespace.

```bash
curl https://kots.io/install | bash
kubectl kots install dbt-cloud-v1 --namespace=<DBT-CLOUD-NAMESPACE>
```

Note that the `kubectl kots install` will prompt the user for a password for the console (a secure password is recommended). Once the admin console is installed, it can be accessed via localhost:8800. After entering the previously created admin console password and a valid license the deployment engineer can continue to the [setup process](https://docs.getdbt.com/docs/dbt-cloud/on-premises/setup) to configure and deploy the dbt Cloud application.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 2.0 |
| local | >= 1.2 |
| null | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| hashicorp/aws | >= 2.0 |
| hashicorp/random | >= 3.0.0 |
| hashicorp/kubernetes | >= 1.9 |
| hashicorp/tls | >= 3.0.0 |

## Module Dependencies

| Name | Version |
|------|---------|
| terraform-aws-modules/acm/aws | 2.12.0 |
| terraform-aws-modules/s3-bucket/aws | 1.16.0 |
| cloudposse/efs/aws | 0.22.0 |
| terraform-aws-modules/eks/aws | 12.2.0 |
| terraform-aws-modules/key-pair/aws | 0.5.0 |
| cloudposse/kms-key/aws | 0.7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_k8s_user_data"></a> [additional\_k8s\_user\_data](#input\_additional\_k8s\_user\_data) | Any additonal user data for K8s worker nodes. For example a curl script to install auditing software. | `string` | `""` | no |
| <a name="input_admin_console_password"></a> [admin\_console\_password](#input\_admin\_console\_password) | Admin Console Script - The desired password for the KOTS admin console. This is added to the script and used when spinning the admin console. | `string` | `"<ENTER_ADMIN_CONSOLE_PASSWORD>"` | no |
| <a name="input_alias_domain_name"></a> [alias\_domain\_name](#input\_alias\_domain\_name) | A valid alias domain for corresponding Route53 record. Must be set if `create_alias_record` is set to `true`. | `string` | `""` | no |
| <a name="input_app_memory"></a> [app\_memory](#input\_app\_memory) | Admin Console Script - The memory dedicated to the application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"1Gi"` | no |
| <a name="input_app_replicas"></a> [app\_replicas](#input\_app\_replicas) | Admin Console Script - The number of application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `number` | `2` | no |
| <a name="input_aws_access_key_id"></a> [aws\_access\_key\_id](#input\_aws\_access\_key\_id) | Admin Console Script - The AWS access key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `"<ENTER_AWS_ACCESS_KEY>"` | no |
| <a name="input_aws_secret_access_key"></a> [aws\_secret\_access\_key](#input\_aws\_secret\_access\_key) | Admin Console Script - The AWS secret key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `"<ENTER_AWS_SECRET_KEY>"` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block of the VPC that the infrastructure will be deployed in. | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster dbt Cloud will be installed into. Must be set if `create_eks_cluster` is set to `false`. | `string` | `""` | no |
| <a name="input_create_admin_console_script"></a> [create\_admin\_console\_script](#input\_create\_admin\_console\_script) | If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with 'Admin Console Script' in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired. | `bool` | `false` | no |
| <a name="input_create_alias_record"></a> [create\_alias\_record](#input\_create\_alias\_record) | Set to `true` to create an alias Route53 record. If set to `true` must enter a valid domain name in the `alias_domain_name` variable. | `bool` | `false` | no |
| <a name="input_create_efs_provisioner"></a> [create\_efs\_provisioner](#input\_create\_efs\_provisioner) | Set to `false` if creating a custom EFS provisioner storage class for the IDE. | `bool` | `true` | no |
| <a name="input_create_eks_cluster"></a> [create\_eks\_cluster](#input\_create\_eks\_cluster) | Set to `false` if installing dbt Cloud into an existing EKS cluster. | `bool` | `true` | no |
| <a name="input_create_loadbalancer"></a> [create\_loadbalancer](#input\_create\_loadbalancer) | Set to `false` if creating a customer load balancer or other networking device to route traffic within the cluster. | `bool` | `true` | no |
| <a name="input_creation_role_arn"></a> [creation\_role\_arn](#input\_creation\_role\_arn) | Admin Console Script - The ARN of the Terraform Creation Role. This is added to the script and used when setting the K8s context. | `string` | `"<ENTER_CREATION_ROLE_ARN>"` | no |
| <a name="input_custom_internal_security_group_id"></a> [custom\_internal\_security\_group\_id](#input\_custom\_internal\_security\_group\_id) | The ID of an existing custom security group attached to an existing K8s cluster. This security group enables communication between the EKS worker nodes, RDS database, and EFS file system. It should be modeled after the `aws_security_group.internal` resource in this module. | `string` | `""` | no |
| <a name="input_custom_namespace"></a> [custom\_namespace](#input\_custom\_namespace) | If set this variable will create a custom K8s namespace for dbt Cloud. If not set the created namespace defaults to `dbt-cloud-<namespace>-<environment>`. | `string` | `""` | no |
| <a name="input_custom_smtp_host"></a> [custom\_smtp\_host](#input\_custom\_smtp\_host) | The host name of the custom (non-SES) SMTP server to use. | `string` | `""` | no |
| <a name="input_custom_smtp_password"></a> [custom\_smtp\_password](#input\_custom\_smtp\_password) | The password of the custom (non-SES) SMTP server to use. | `string` | `""` | no |
| <a name="input_custom_smtp_username"></a> [custom\_smtp\username](#input\_custom\_smtp\_username) | The username of the custom (non-SES) SMTP server to use. | `string` | `""` | no |
| <a name="input_datadog_agent_memory_limit"></a> [datadog\_agent\_memory\_limit](#input\_datadog\_agent\_memory\_limit) | The resource memory limit of the Datadog agent. | `string` | `"512Mi"` | no |
| <a name="input_datadog_agent_memory_request"></a> [datadog\_agent\_memory\_request](#input\_datadog\_agent\_memory\_request) | The resource memory request of the Datadog agent. | `string` | `"256Mi"` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | If `enable_datadog` is set to `true`, this variable must be set to valid API key of the destination Datadog account. | `string` | `""` | no |
| <a name="input_eks_ami"></a> [eks\_ami](#input\_eks\_ami) | Default to pull the latest Ubuntu EKS AMI, otherwise use this one. | `string` | `""` | no |
| <a name="input_enable_bastion"></a> [enable\_bastion](#input\_enable\_bastion) | Enable bastion host that has ssh access to worker nodes. | `bool` | `false` | no |
| <a name="input_enable_datadog"></a> [enable\_datadog](#input\_enable\_datadog) | If set to `true` this will enable dbt Cloud to send metrics to Datadog. Note that this requires the installation of a Datadog Agent in the K8s cluster where dbt Cloud is deployed. | `bool` | `false` | no |
| <a name="input_enable_datadog_apm"></a> [enable\_datadog\_apm](#input\_enable\_datadog\_apm) | Set to `true` to enable APM (tracer agent) for Datadog. Will only take effect if `enable_datadog_agent` is also set to `true`. | `bool` | `false` | no |
| <a name="input_enable_datadog_cluster_agent"></a> [enable\_datadog\_cluster\_agent](#input\_enable\_datadog\_cluster\_agent) | Set to `true` to enable cluster agent for Datadog. Will only take effect if `enable_datadog_agent` is also set to `true`. | `bool` | `false` | no |
| <a name="input_enable_datadog_kube_state_metrics"></a> [enable\_datadog\_kube\_state\_metrics](#input\_enable\_datadog\_kube\_state\_metrics) | Set to `true` to enable kube state metrics for Datadog. Will only take effect if `enable_datadog_agent` is also set to `true`. | `bool` | `false` | no |
| <a name="input_enable_datadog_process_agent"></a> [enable\_datadog\_process\_agent](#input\_enable\_datadog\_process\_agent) | Set to `true` to enable process agent for Datadog. Will only take effect if `enable_datadog_agent` is also set to `true`. | `bool` | `false` | no |
| <a name="input_enable_kube_cleanup_operator"></a> [enable\_kube\_cleanup\_operator](#input\_enable\_kube\_cleanup\_operator) | Set to `false` to disable kube-cleanup-operator deployment. | `bool` | `true` | no |
| <a name="input_enable_reloader"></a> [enable\_reloader](#input\_enable\_reloader) | Set to `false` to disable reloader. | `bool` | `true` | no |
| <a name="input_enable_ses"></a> [enable\_ses](#input\_enable\_ses) | If set to `true` this will attempt to create an key pair for AWS Simple Email Service. If set to `true` a valid from email address must be set in the `ses_email` variable. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment for the deployment. For example: 'dev', 'prod', 'uat', 'standard', 'etc' | `string` | n/a | yes |
| <a name="input_existing_namespace"></a> [existing\_namespace](#input\_existing\_namespace) | If set to `true`this will install dbt Cloud components into an existing namespace denoted by the `custom_namespace` field. This is not recommended as it is preferred to install dbt Cloud into a dedicated namespace. | `bool` | `false` | no |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | The root domain name of the hosted zone that will resolve to the dbt Cloud deployment. This should be a valid domain name that you own. | `string` | n/a | yes |
| <a name="input_hostname_affix"></a> [hostname\_affix](#input\_hostname\_affix) | The affix of the URL, affixed to the `hosted_zone_name` variable, that the dbt Cloud deployment will resolve to. If left blank the affix will default to the value of the `environment` variable. | `string` | `""` | no |
| <a name="input_ide_storage_class"></a> [ide\_storage\_class](#input\_ide\_storage\_class) | Admin Console Script - The EFS provisioner storage class name used for the IDE. Only change if creating a custom EFS provisioner. | `string` | `"aws-efs"` | no |
| <a name="input_k8s_node_count"></a> [k8s\_node\_count](#input\_k8s\_node\_count) | The number of Kubernetes nodes that will be created for the EKS worker group. Generally 2 nodes are recommended but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `number` | n/a | yes |
| <a name="input_k8s_node_size"></a> [k8s\_node\_size](#input\_k8s\_node\_size) | The EC2 instance type of the Kubernetes nodes that will be created for the EKS worker group. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| <a name="input_key_admins"></a> [key\_admins](#input\_key\_admins) | Required list of admin users for KMS key creation. This list should include at least one valid admin user for the AWS account. | `list(string)` | n/a | yes |
| <a name="input_key_users"></a> [key\_users](#input\_key\_users) | List of key users for the KMS key creation. This can be left as an empty list unless adding users to KMS key is desired. | `list(string)` | `[]` | no |
| <a name="input_load_balancer_source_ranges"></a> [load\_balancer\_source\_ranges](#input\_load\_balancer\_source\_ranges) | A list of IP ranges in CIDR notation that will be whitelisted by the loadbalancer. If unset will default to allow all traffic. | `list(string)` | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Used as an identifier for various infrastructure components within the module. Usually single word that or the name of the organization. For exmaple: 'fishtownanalytics' | `string` | n/a | yes |
| <a name="input_nginx_memory"></a> [nginx\_memory](#input\_nginx\_memory) | Admin Console Script - The amount of memory dedicated to nginx for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"512Mi"` | no |
| <a name="input_postgres_instance_class"></a> [postgres\_instance\_class](#input\_postgres\_instance\_class) | The RDS Postgres instance type. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| <a name="input_postgres_storage"></a> [postgres\_storage](#input\_postgres\_storage) | The amount of storage allocated to the RDS database in GB. Generally 100 GB is standard but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | The list of private subnets for the VPC that the infrastructure will be deployed in. | `list(string)` | n/a | yes |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | The list of public subnets for the VPC that the infrastructure will be deployed in. | `list(string)` | `[]` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | The number of days for RDS to create automated snapshot backups. Set to a max of 35 or set to 0 to disable automated backups. | `number` | `7` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | Set to `false` to disable Multi-AZ deployment for Postgres RDS database. | `bool` | `true` | no |
| <a name="input_postgres_engine_version"></a> [postgres\_engine\_version](#input\_postgres\_engine\_version) | The postgres engine version to use for the RDS database. | `string` | `12.5` | no |
| <a name="input_db_parameter_group"></a> [db\_parameter\_group](#input\_db\_parameter\_group) | The db parameter group to apply to the RDS database. | `string` | `default.postgres12` | no |
| <a name="input_db_apply_change_immediately"></a> [db\_apply\_change\_immediately](#input\_db\_apply\_change\_immediately) | Set to `false` to apply RDS database changes at next scheduled maintenance window. | `bool` | `true` | no |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | Password for RDS database. It is highly recommended that a secure password be generated and stored in a vault. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where the infrastructure will be deployed. For example 'us-east-1'. | `string` | n/a | yes |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | Admin Console Script - The license channel for customer deployment. This should be left unset unless instructed by Fishtown Analytics. | `string` | `""` | no |
| <a name="input_scheduler_memory"></a> [scheduler\_memory](#input\_scheduler\_memory) | Admin Console Script - The amount of memory dedicated to the scheduler for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"512Mi"` | no |
| <a name="input_from_email"></a> [from\_email](#input\_from\_email) | The email address the system will send emails from via SMTP server. If `enable_ses = true`, this address will receive a validation email from AWS upon apply. | `string` | `""` | no |
| <a name="input_from_header"></a> [from\_header](#input\_from\_header) | The email header for notifications sent via SMTP server. If left blank the header will simply display as the address set in the `from_email` variable. | `string` | `""` | no |
| <a name="input_superuser_password"></a> [superuser\_password](#input\_superuser\_password) | Admin Console Script - The superuser password for the dbt Cloud application. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `"<ENTER_SUPER_USER_PASSWORD>"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of the VPC that the infrastructure will be deployed in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_hostname"></a> [database\_hostname](#output\_database\_hostname) | The hostname (address) of the RDS database generated. This is required to be entered manually in the configuration console if not using the generated script. |
| <a name="output_efs_dns_name"></a> [efs\_dns\_name](#output\_efs\_dns\_name) | The DNS name generated for the EFS instance. This may be required if creating a custom EFS provisioner. |
| <a name="output_efs_id"></a> [efs\_id](#output\_efs\_id) | The ID generated for the EFS instance. This may be required if creating a custom EFS provisioner. |
| <a name="output_instance_url"></a> [instance\_url](#output\_instance\_url) | The URL where the dbt Cloud instance can be accessed. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The ARN of the KMS key created. May be manually entered for encryption in the configuration console if not using the generated script. |
