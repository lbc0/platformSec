.RECIPEPREFIX = >
TF := terraform -chdir=terraform

.PHONY: init infra inventory configure up down rebuild scan versions

init:
> $(TF) init

infra:
> $(TF) apply -auto-approve

inventory:
> mkdir -p .kube
> $(TF) output -json ansible_inventory > ansible/inventory/generated.json

configure:
> cd ansible && ansible-playbook playbooks/site.yml

up: infra inventory configure

down:
> $(TF) destroy -auto-approve
> rm -f ansible/.known_hosts ansible/inventory/generated.json .kube/lab.conf

rebuild: down up

scan:
> trivy config --exit-code 1 --severity HIGH,CRITICAL terraform/
> trivy fs --scanners secret --exit-code 1 --skip-dirs terraform/.terraform --skip-dirs tests .

versions:
> bash scripts/versions.sh
