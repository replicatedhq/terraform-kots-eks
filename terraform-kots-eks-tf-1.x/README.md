# AWS Terraform KOTS EKS

This terraform workflow will quick start all the necessary components for creating an EKS cluster inside of a defined VPC and deliver a Kubernetes Off-The-Shelf ([**KOTS**](https://kots.io)) third party application. Leveraging the [AWS ALB Controller](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md) and [ExternalDNS](https://github.com/kubernetes-sigs/external-dns) to control Route53 DNS records along with exposing ingress addresses externally.

## Requirements
- Replicated Vendor Portal Account
  - Visit https://vendor.replicated.com
- Replicated KOTS application
  - See [Packaging KOTS Applications](https://kots.io/vendor/packaging/packaging-an-app/)
- AWS Account with IAM Permissions to provision components listed below
- Terraform 1.0.x
- A Domain i.e. example.com 

## AWS Components Created
- AWS LB
- AWS VPC and Subnets
- AWS EKS Cluster
- AWS ACM Certificates
- AWS Route53 Record(s)

## Outcome
After running the Terraform plan you will have an AWS EKS cluster inside of a defined VPC along with DNS enteries for accessing the KOTS Admin Console and example Sentry Pro third party application.


![KOTS EKS](/terraform-kots-eks-tf-1.x/images/terraform-kots-eks.png)

## Deploying Infrastructure and KOTS
1. Run `terraform init` to initialize workspace
2. Add you KOTS application license file to root path i.e kots-license.yaml
3. Create a file called `kots-eks.tfvars` with the following content (CHANGE_ME where needed):
    ```
    admin_console_config_yaml   = "apiVersion: kots.io/v1beta1\nkind: ConfigValues\nmetadata:\n  creationTimestamp: null\n  name: changeme\nspec:\n  values: {}\nstatus: {}\n"
    admin_console_password      = "password@!"
    app_slug                    = "CHANGE_ME"
    aws_region                  = "CHANGE_ME"
    cluster_name                = "CHANGE_ME"
    create_admin_console_script = true
    hosted_zone_id              = "CHANGE_ME"
    hosted_zone_name            = "CHANGE_ME"
    instance_type               = "t2.xlarge"
    k8s_namespace               = "default"
    kotsadm_fqdn                = "CHANGE_ME"
    license_file_path           = "./kots-license.yaml"
    load_balancer_source_ranges = "0.0.0.0/0"
    load_balancers              = {}
    namespace_exists            = false
    release_channel             = ""
    sentry_admin_password       = "password"
    sentry_admin_username       = "admin@example.com"
    sentry_fqdn                 = "CHANGE_ME"
    subject_alternative_names   = ["CHANGE_ME"]
    vpc_cidr                    = "172.16.0.0/16"
    vpc_name                    = "CHANGE_ME"
    vpc_private_subnet = [
      "172.16.1.0/24",
      "172.16.2.0/24",
      "172.16.3.0/24"
    ]
    vpc_public_subnet = [
      "172.16.4.0/24",
      "172.16.5.0/24",
      "172.16.6.0/24"
    ]
    ```
4. Run `terraform plan -var-file="kots-eks.tfvars" --out eks-plan` and input variable prompts (if not supplied in variables.tf)
5. Run `terraform apply "eks-plan"` to start creating the infrastructure and install the KOTS sample application.
    - Get some coffee or water, it will take some time (approx 20 minutes) to create and deploy the application

6. Once complete you should now be able to visit the KOTS Admin Console and Sentry Pro application URLs (i.e https://kotsadm.example.com and https://sentry.example.com)

## Using Docker To Deploy
1. Navigate to **deploy** directory
2. Create environment variables for with your `export AWS_ACCESS_KEY_ID=<key>` and `export AWS_SECRET_ACCESS_KEY=<secret>`
2. Update variables.tf file
3. Comment out lines 138 - 159 in main.tf. 
    - The `install.sh` and `patch_kots_service.sh` files are created during the terraform apply but are not mounted on the container during creation and will not be available to run.
4. To initialize execute `docker-compose run --rm terraform init`
5. To plan execute `docker-compose run --rm terraform plan`
5. To run execute `docker-compose run --rm terraform apply`
5. Copy and run contents of `install.sh` and `pactch_kots_service.sh` after EKS cluster is up

## Clean Up
1. On the EKS cluster context delete the ingress(es)that were created.
    - `kubectl delete -n <namespace> ingress <ingress-kotsadm-name>`
    - Repeat for all ingress(es) created 
2. Run `terraform destroy`
    - If using docker-compose.yaml follow step 1 above then run `docker-compose run --rm terraform destroy` from deploy directory
