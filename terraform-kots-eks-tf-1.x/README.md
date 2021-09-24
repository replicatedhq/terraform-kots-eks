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
3. Copy `terraform.tfvars.example` to `terraform.tfvars` and add the missing values.  Review [variables.tf](/variables.tf) for other values that can be changed.
4. Run `terraform plan --out eks-plan` and input variable prompts (if not supplied in variables.tf)
5. Run `terraform apply "eks-plan"` to start creating the infrastructure and install the KOTS sample application.
    - Get some coffee or water, it will take some time (approx 20 minutes) to create and deploy the application

6. Once complete you should now be able to visit the KOTS Admin Console and Sentry Pro application URLs (i.e https://kotsadm.example.com and https://sentry.example.com). It can take up to 20 minutes for the A records to propagate.

## Using Docker To Deploy
1. Create environment variables for with your `export AWS_ACCESS_KEY_ID=<key>` and `export AWS_SECRET_ACCESS_KEY=<secret>`
1. Update variables.tf file
1. Comment out lines 138 - 159 in main.tf. 
    - The `install.sh` and `patch_kots_service.sh` files are created during the terraform apply but are not mounted on the container during creation and will not be available to run.
1. To initialize execute `docker-compose run --rm terraform init`
1. To plan execute `docker-compose run --rm terraform plan`
1. To run execute `docker-compose run --rm terraform apply`
1. Copy and run contents of `install.sh` and `pactch_kots_service.sh` after EKS cluster is up

## Clean Up
1. Run `terraform destroy -var-file="kots-eks.tfvars"`
    - If using docker-compose.yaml follow step 1 above then run `docker-compose run --rm terraform destroy` from deploy directory
