# Cloud infrastructure (Terraform)

All cloud resources for the lab are managed here. Anything local (a VM on your laptop) stays in bash under [`../setup/`](../setup/).

| Stack | What it creates | When to use it | Lifetime |
| --- | --- | --- | --- |
| [`lab-vm-gcp/`](lab-vm-gcp/) | Ubuntu 24.04 e2-standard-8 VM in its own VPC, SSH through IAP only, optional budget alert | The main lab machine, if your laptop is too small | The whole 4 weeks; stop it between sessions |
| [`gke-dataplane-v2/`](gke-dataplane-v2/) | Zonal GKE cluster with Dataplane V2 (Google-managed Cilium) and Hubble relay | Week 4 cloud session: compare managed Cilium with your kind lab | A few hours; destroy the same day |
| [`eks-vpc-cni/`](eks-vpc-cni/) | VPC with one NAT gateway, and an EKS cluster using the AWS VPC CNI | Week 4 cloud session: pod IPs from VPC subnets, IP limits, prefix delegation | A few hours; destroy the same day |

Each stack is independent, with its own local state. Use a personal cloud account for all of them.

## Prerequisites

- Terraform 1.5 or later
- GCP stacks: `gcloud auth application-default login`, a personal project, and billing enabled
- EKS stack: AWS credentials (`aws configure` or SSO) for a personal account

## Usage

```bash
cd terraform/<stack>
cp terraform.tfvars.example terraform.tfvars   # fill in your values
terraform init
terraform plan
terraform apply
terraform output                               # connection commands
terraform destroy                              # when you are done
```

## Lab VM day to day

```bash
cd terraform/lab-vm-gcp
terraform apply -var running=true    # start a session
$(terraform output -raw ssh_command) # SSH through IAP
terraform apply -var running=false   # stop: compute billing stops, the disk is kept
```

For VS Code Remote-SSH, run the SSH command once so gcloud creates your key, then paste `terraform output -raw vscode_ssh_config` into `~/.ssh/config` and replace `YOUR_USER`.

## Cost guardrails

- Destroy the GKE and EKS stacks the same day. Both bill for the control plane, nodes and (for EKS) the NAT gateway by the hour.
- The EKS stack makes you choose `kubernetes_version`. Pick a version in standard support; older versions bill extra for extended support.
- Set `billing_account_id` in `lab-vm-gcp` to get budget emails at 50%, 90% and 100% of `budget_usd`.
- Spot nodes are on by default for the GKE and EKS stacks; the lab VM defaults to standard so a session isn't interrupted.
