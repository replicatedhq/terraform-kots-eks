# terraform-kots-eks

A terraform module for deploying KOTS applications in managed EKS clusters in a uniform way. This is a module for building modules - you can use it to create a terraform module that deploys your app in an EKS cluster with ACM Certs, DNS, and load balancers.

The module itself is in `terraform-kots-eks`.
A working example is in `examples/kots-sentry`
The previous DBT stuff lives in a work-in-progress module in `dbt` and `dbt/examples`.

## Bootstrapping steps

The following steps are required prior to running the terraform-kots-eks module to provision infrastructure in AWS using terraform.

### Creating an AWS Profile

To connect to the aws account run `aws configure --profile <PROFILE_NAME>` and enter valid AWS secret values for an IAM user in the account where you will be installing the dbt Cloud application. After running the above command, make sure that the current AWS profile is set by running `export AWS_PROFILE=<PROFILE_NAME>` (for Mac users) or `setx AWS_PROFILE <PROFILE_NAME>` (for Windows users). Note that this profile will be needed later when setting the Kubernetes context after infrastructure is configured.

### Terraform Creator IAM Role Creation

<!-- this is from the DBT project and needs review -->

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

Once created the role arn should be entered in the "creation_role_arn" variable in the `vars.tf` file for each environment directory. The role is assumed by Terraform in the aws provider for each environment. Note that this role will be needed again when installing KOTS and the application.

### VPC Creation

The infrastructure needed to host the KOTS EKS cluster in AWS must live in a VPC configured outside of this module. Examples of how to create such a VPC using Terraform can be seen in the kots-sentry example in this module.

## Configuration Process

After creating the infrastructure by running `terraform apply` the following steps must be run to configure the infrastructure for the dbt Cloud application.

## Installation Process

After the environment configuration is complete the dbt Cloud application can be configured and installed via the Replicated (KOTS) admin console. If the optional 'create_admin_console_script' variable was set to true then a script and corresponding config file will be created to automatically install the KOTS admin console will pre-filled values populated from other related optional variables and the infrastructure build by Terraform (such as RDS hostname). This script can simply by ran from the shell with `./kots_install.sh`. Once the admin console is installed it can be accessed via localhost:8800. 

If the `create_admin_console_script` variable was not set to true, the KOTS admin console can be manually configured using the following steps below.

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
| hashicorp/kubernetes | >= 1.9 |
