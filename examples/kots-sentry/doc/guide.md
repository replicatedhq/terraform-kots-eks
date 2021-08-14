
# Prerequisites
1. Have `git` cli installed
1. Have `terraform` cli installed


# Steps
1. Clone the repo: `git clone git@github.com:replicatedhq/terraform-kots-eks.git`
1. Go to the sentry example: `cd terraform-kots-eks/examples/kots-sentry`
1. Install the kubectl kots plugin: `curl https://kots.io/install | bash`
1. Initialize terraform working directory: `terraform init`
1. Create a file `terraform.tfvars` with the following content (change where needed):
    ```
    admin_console_password        = ""
    cidr_block                    = "10.191.0.0/16"
    create_load_lbs_dns_and_certs = true
    environment                   = "prod"
    hosted_zone_name              = ""
    k8s_namespace                 = "kots-sentry"
    license_file_path             = "./kots-sentry.yaml"
    load_balancer_source_ranges = [
    "0.0.0.0/0"
    ]
    namespace             = "somebigbank"
    region                = "eu-central-1"
    sentry_admin_password = "sentry1@!"
    sentry_admin_username = "admin@example.com"
    subnets = {
    "private": {
        "eu-central-1a": "10.191.0.0/20",
        "eu-central-1b": "10.191.16.0/20",
        "eu-central-1c": "10.191.32.0/20"
    },
    "public": {
        "eu-central-1a": "10.191.64.0/20",
        "eu-central-1b": "10.191.80.0/20",
        "eu-central-1c": "10.191.96.0/20"
    }
    }
    ```
1. Run `terraform plan -var-file=terraform.tfvars`
1. Run `terraform apply -var-file=terraform.tfvars`