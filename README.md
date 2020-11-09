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
| terraform | >= 0.12.0 |
| aws | >= 2.0 |
| local | >= 1.2 |
| null | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| hashicorp/aws | >= 2.0 |
| hashicorp/random | >= 3.0.0 |
| hashicorp/kubernetes | >= 1.13.0 |
| hashicorp/tls | >= 3.0.0 |

## Module Dependencies

| Name | Version |
|------|---------|
| terraform-aws-modules/acm/aws | 2.12.0 |
| terraform-aws-modules/s3-bucket/aws | 1.8.0 |
| cloudposse/efs/aws | 0.16.0 |
| terraform-aws-modules/eks/aws | 12.2.0 |
| terraform-aws-modules/key-pair/aws | 0.4.0 |
| cloudposse/kms-key/aws | 0.5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| namespace | Used as an identifier for various infrastructure components within the module. Usually single word that or the name of the organization. For exmaple: `fishtownanalytics` | `string` | n/a | yes |
| environment | The name of the environment for the deployment. For example: `dev`, `prod`, `uat`, `standard`, etc | `string` | n/a | yes |
| k8s_node_count | The number of Kubernetes nodes that will be created for the EKS worker group. Generally 2 nodes are recommended but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `number` | n/a | yes |
| k8s_node_size | The [EC2 instance type](https://aws.amazon.com/ec2/instance-types/) of the Kubernetes nodes that will be created for the EKS worker group. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| region | The AWS region where the infrastructure will be deployed. For example `us-east-1`. | `string` | n/a | yes |
| postgres_instance_class | The [RDS Postgres instance type](https://aws.amazon.com/rds/instance-types/). It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| postgres_storage | The amount of storage allocated to the RDS database in GB. Generally 100 GB is standard but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this. | `string` | n/a | yes |
| cidr_block | The CIDR block of the VPC that the infrastructure will be deployed in. | `string` | n/a | yes |
| key_admins | Required list of admin users for KMS key creation. This list should include at least one valid admin user for the AWS account. | `list(string)`| n/a | yes |
| rds_password | Password for RDS database. It is highly recommended that a secure password be generated and stored in a vault. | `string` | n/a | yes |
| vpc_id | The ID of the VPC that the infrastructure will be deployed in. | `string` | n/a | yes |
| private_subnets | The list of private subnets for the VPC that the infrastructure will be deployed in. | `list(string)` | n/a | yes |
| hosted_zone_name | The root domain name of the hosted zone that will resolve to the dbt Cloud deployment. This should be a valid domain name that you own. | `string` | n/a | yes |
| key_users | List of key users for the KMS key creation. This can be left as an empty list unless adding users to KMS key is desired. | `list(string)` | [] | no |
| enable_ses | If set to 'true' this will attempt to create an key pair for AWS Simple Email Service. If set to `true` a valid from email address must be set in the 'ses_email' variable. | `bool` | `false` | no |
| ses_email | A valid from email address to be used for AWS SES. This address will receive a validation email from AWS upon apply. | `string` | `""` | no |
| ses_header | The email header for notifications sent via SES. If left blank the header will simply display as the address set in the `ses_email` variable. | `string` | `""` | no |
| load_balancer_source_ranges | A list of IP ranges in CIDR notation that will be whitelisted by the loadbalancer. If unset will default to allow all traffic. | `list(string)` | `[]` | no |
| create_admin_console_script | If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with `Admin Console Script` in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired. | `bool` | `false` | no |
| aws_access_key_id | Admin Console Script - The AWS access key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `"<ENTER_AWS_ACCESS_KEY>"` | no |
| aws_secret_access_key | Admin Console Script - The AWS secret key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `<ENTER_AWS_SECRET_KEY>` | no |
| creation_role_arn | Admin Console Script - The ARN of the Terraform Creation Role. This is added to the script and used when setting the K8s context. | `string` | `"<ENTER_CREATION_ROLE_ARN>"` | no |
| admin_console_password | Admin Console Script - The desired password for the KOTS admin console. This is added to the script and used when spinning the admin console. | `string` | `"<ENTER_ADMIN_CONSOLE_PASSWORD>"` | no |
| superuser_password | Admin Console Script - The superuser password for the dbt Cloud application. This is added to the config that is automatically uploaded to the KOTS admin console via the script. | `string` | `"<ENTER_SUPER_USER_PASSWORD>"` | no |
| datadog_enabled | If set to `true` this will enable dbt Cloud to send metrics to Datadog. Note that this requires the installation of a Datadog Agent in the K8s cluster where dbt Cloud is deployed. | `bool` | `false` | no |
| hostname_affix | The affix of the URL, affixed to the `hosted_zone_name` variable, that the dbt Cloud deployment will resolve to. If left blank the affix will default to the value of the `environment` variable. | `string` | `""` | no |
| release_channel | Admin Console Script - The license channel for customer deployment. This should be left unset unless instructed by Fishtown Analytics. | `string` | `""` | no |
| app_memory | Admin Console Script - The memory dedicated to the application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"1Gi"` | no |
| app_replicas | Admin Console Script - The number of application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `number` | `2` | no |
| nginx_memory | Admin Console Script - The amount of memory dedicated to nginx for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"500mi"` | no |
| scheduler_memory | Admin Console Script - The amount of memory dedicated to the scheduler for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this. | `string` | `"1Gi"` | no |
| set_additional_k8s_user_data | Set to true to add additional user data for K8s worker nodes using the `additional_k8s_user_data` variable. | `bool` | `false` | no |
| additional_k8s_user_data | Any additonal user data for K8s worker nodes. For example a curl script to install auditing software. | `string` | `""` | no |
| create_efs_provisioner | Set to `false` if creating a custom EFS provisioner storage class for the IDE. | `bool` | `true` | no |
| ide_storage_class | dmin Console Script - The EFS provisioner storage class name used for the IDE. Only change if creating a custom EFS provisioner. | `string` | `"aws-efs"` | no |
| create_loadbalancer | Set to `false` if creating a customer load balancer or other networking device to route traffic within the cluster. | `bool` | `true` | no |
| rds_backup_retention_period | The number of days for RDS to create automated snapshot backups. Set to a max of 35 or set to 0 to disable automated backups. | `number` | `7` | no|
