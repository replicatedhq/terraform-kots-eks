


#### Creating a Key Pair

Your key-pair should match the `namespace` and `environment` variables you pass in.
If you're using `somebigbank` and `prod` respectively, then your key name should be
`somebigbank-prod`.

```
aws --region=ca-central-1 ec2 create-key-pair --key-name somebigbank-prod
```

and save the private key somewhere.


#### Running it

```
terraform init
terraform apply
```

#### kots install

```shell
./kots_install.sh
```

This will prompt for a password, so *if you want* you can pre-install kots CLI with

```shell
curl https://kots.io/install | bash
```
