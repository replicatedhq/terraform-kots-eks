aws eks update-kubeconfig --profile bankgadol-dbt-cloud-single-tenant --name bankgadol-prods --role-arn --role-arn=<ENTER_CREATION_ROLE_ARN>
kubectl config set-context --current --namespace=kots-sentry
[[ -x $(which kubectl-kots) ]] || curl https://kots.io/install | bash
kubectl kots install kots-sentry --namespace kots-sentry --license-file ./kots-sentry.yaml --shared-password sooperSecret --config-values ./config.yaml
