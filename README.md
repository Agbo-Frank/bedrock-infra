# Project Bedrock

Production-grade deployment of the [AWS Retail Store Sample App](https://github.com/aws-containers/retail-store-sample-app) on Amazon EKS, built as the AltSchool Africa Cloud Engineering capstone project.

---

## Architecture

```
                        Internet
                           │
                    ┌──────▼──────┐
                    │     ALB     │  ← provisioned by EKS Auto Mode
                    └──────┬──────┘
                           │ HTTP :80
                    ┌──────▼──────┐
                    │  ui (React) │  namespace: retail-app
                    └──────┬──────┘
           ┌───────────────┼───────────────┐
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │   catalog   │ │   orders    │ │  checkout   │
    │  (Go/MySQL) │ │(Java/PgSQL) │ │   (Node)    │
    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
           │               │               │
    ┌──────▼──────┐  ┌──────▼──────┐ ┌──────▼──────┐
    │  RDS MySQL  │  │  RDS PgSQL  │ │   RabbitMQ  │
    └─────────────┘  └─────────────┘ └─────────────┘
                                             │
                                      ┌──────▼──────┐
                                      │    cart     │
                                      │ (Java/DDB)  │
                                      └──────┬──────┘
                                      ┌──────▼──────┐
                                      │  DynamoDB   │
                                      └─────────────┘
                                      ┌─────────────┐
                                      │    Redis    │
                                      │  (session)  │
                                      └─────────────┘
```

**AWS services used:**

| Service | Purpose |
|---|---|
| EKS Auto Mode | Kubernetes cluster (manages nodes, load balancer controller) |
| RDS MySQL | Catalog service database |
| RDS PostgreSQL | Orders service database |
| DynamoDB | Cart service (items per user) |
| S3 | Static product image assets |
| Lambda (Node.js) | Processes S3 upload events |
| Secrets Manager | RDS passwords (auto-generated) |
| CloudWatch | Logs via Fluent Bit DaemonSet (EKS add-on) |
| GitHub Actions OIDC | CI/CD — no long-lived credentials stored |

---

## Repository structure

```
bedrock-infra/
├── terraform/
│   ├── main.tf               # root module: backend, providers, module calls
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── vpc/              # VPC, subnets, NAT gateways
│       ├── eks/              # EKS Auto Mode cluster, OIDC provider, CloudWatch add-on
│       ├── rds/              # MySQL + PostgreSQL, Secrets Manager passwords
│       ├── dynamodb/         # Cart table
│       ├── iam/              # bedrock-dev-view user, cart IRSA role
│       ├── lambda/           # S3 bucket, Lambda function, S3 notification
│       └── github_oidc/      # GitHub Actions OIDC role
├── k8s/
│   ├── namespace.yaml
│   ├── ingressclass.yaml     # Required for EKS Auto Mode ALB
│   ├── ingress.yaml
│   ├── rbac/
│   ├── infra/                # Redis, RabbitMQ
│   ├── backend/
│   │   ├── cart/
│   │   ├── catalog/
│   │   ├── checkout/
│   │   └── orders/
│   └── frontend/ui/
├── lambda/
│   └── index.js              # S3 event handler
├── scripts/
│   ├── common.sh             # Shared utilities (sourced by all scripts)
│   ├── deploy.sh             # Top-level entry point — runs terraform + k8s
│   ├── terraform/
│   │   ├── main.sh           # Entry point: plan | apply | destroy
│   │   ├── plan.sh
│   │   ├── apply.sh
│   │   └── destroy.sh
│   └── k8s/
│       ├── main.sh           # Entry point: configure | manifests | secrets | configmaps | all
│       ├── configure.sh
│       ├── manifests.sh
│       ├── secrets.sh
│       └── configmaps.sh
└── .github/workflows/
    ├── terraform-plan.yml    # runs on PR → posts plan as comment
    └── terraform-apply.yml   # runs on merge to main → applies
```

---

## Prerequisites

Install these tools before running anything:

| Tool | Minimum version | Install |
|---|---|---|
| Terraform | 1.5.0 | `brew install terraform` |
| AWS CLI | v2 | `brew install awscli` |
| kubectl | 1.28+ | `brew install kubectl` |
| jq | any | `brew install jq` |

---

## One-time setup

These steps are done once before the first deployment.

### 1. Configure AWS credentials

```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region: us-east-1
# Default output format: json
```

Verify access:

```bash
aws sts get-caller-identity
```

### 2. Create the Terraform state bucket

The S3 bucket that stores Terraform state must be created manually before running `terraform init`.

```bash
aws s3api create-bucket \
  --bucket bedrock-terraform-state-861079997875 \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket bedrock-terraform-state-861079997875 \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket bedrock-terraform-state-861079997875 \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### 3. Set your GitHub username

In `terraform/main.tf`, update the `github_oidc` module:

```hcl
module "github_oidc" {
  source          = "./modules/github_oidc"
  title           = var.title
  github_username = "YOUR_GITHUB_USERNAME"   # ← change this
  github_repo     = "project-bedrock"
}
```

### 4. Create your GitHub repository

Create a repo named `project-bedrock` on GitHub, then push this code:

```bash
git remote add origin git@github.com:YOUR_GITHUB_USERNAME/project-bedrock.git
git push -u origin main
```

### 5. Add the GitHub secret (after first apply)

After running `terraform apply`, add `AWS_ROLE_ARN` to your GitHub repo secrets:

```
GitHub repo → Settings → Secrets and variables → Actions → New repository secret
Name:  AWS_ROLE_ARN
Value: <output from terraform: github_oidc_role_arn>
```

---

## Deployment

### Full deployment (first time)

```bash
./scripts/deploy.sh
```

This runs everything end-to-end:
1. `terraform apply` — provisions all AWS infrastructure (~15-20 min)
2. `aws eks update-kubeconfig` — points kubectl at the new cluster
3. Applies all Kubernetes manifests in the correct order
4. Creates Kubernetes secrets from Secrets Manager passwords
5. Patches ConfigMaps with the live RDS endpoint addresses
6. Re-applies manifests so pods restart with the correct config

### Step-by-step (recommended when learning)

```bash
# 1. Preview what terraform will create
./scripts/terraform/main.sh plan

# 2. Apply infrastructure
./scripts/terraform/main.sh apply

# 3. Configure kubectl
./scripts/k8s/main.sh configure

# 4. Deploy all Kubernetes resources
./scripts/k8s/main.sh manifests

# 5. Create secrets (RDS passwords)
./scripts/k8s/main.sh secrets

# 6. Patch configmaps with real RDS endpoints
./scripts/k8s/main.sh configmaps

# 7. Re-apply so pods pick up the updated config
./scripts/k8s/main.sh manifests
```

### Re-deploy k8s only (terraform already applied)

```bash
./scripts/deploy.sh --k8s-only
```

---

## Accessing the application

After deployment, get the ALB address:

```bash
kubectl get ingress -n retail-app
```

The `ADDRESS` column shows the ALB DNS name. It takes ~2 minutes for the ALB to be provisioned after the Ingress is created.

```
NAME             CLASS   HOSTS   ADDRESS                                          PORTS
retail-ingress   alb     *       k8s-retailapp-xxx.us-east-1.elb.amazonaws.com   80
```

Open `http://<ADDRESS>` in a browser.

---

## CI/CD pipeline

The GitHub Actions workflows in `.github/workflows/` handle automated deployments.

| Event | Workflow | What it does |
|---|---|---|
| Pull request to `main` | `terraform-plan.yml` | Runs `terraform plan` and posts the output as a PR comment |
| Merge to `main` | `terraform-apply.yml` | Runs `terraform apply` automatically |

Authentication uses OIDC — GitHub never stores AWS access keys. The `AWS_ROLE_ARN` secret must be set (see one-time setup step 5).

---

## Useful commands

```bash
# View all resources in the app namespace
kubectl get all -n retail-app

# Watch pod startup
kubectl get pods -n retail-app -w

# View logs for a service
kubectl logs -n retail-app deploy/ui
kubectl logs -n retail-app deploy/catalog
kubectl logs -n retail-app deploy/cart

# Describe a pod (useful for debugging CrashLoopBackOff)
kubectl describe pod -n retail-app <pod-name>

# Check the ingress and ALB address
kubectl get ingress -n retail-app

# Check nodes (EKS Auto Mode provisions these on demand)
kubectl get nodes
```

---

## Terraform outputs

After `terraform apply`, these outputs are available:

```bash
terraform -chdir=terraform output
```

| Output | Description |
|---|---|
| `cluster_name` | EKS cluster name (`project-bedrock-cluster`) |
| `cluster_endpoint` | Kubernetes API server URL |
| `region` | AWS region |
| `vpc_id` | VPC ID |
| `assets_bucket_name` | S3 bucket for product images |
| `cart_irsa_role_arn` | IAM role ARN annotated on the cart ServiceAccount |
| `github_oidc_role_arn` | IAM role ARN for GitHub Actions — set as `AWS_ROLE_ARN` repo secret |

---

## Tearing down

```bash
./scripts/terraform/main.sh destroy
```

You will be prompted to type `yes` to confirm. This destroys all AWS resources managed by Terraform. The Terraform state S3 bucket is not deleted — remove it manually if needed.

---

## Grading constraints

| Constraint | Value |
|---|---|
| EKS cluster name | `project-bedrock-cluster` |
| VPC name | `project-bedrock-vpc` |
| Kubernetes namespace | `retail-app` |
| IAM user | `bedrock-dev-view` |
| S3 assets bucket | `bedrock-assets-alt-soe-025-4161` |
| Lambda function | `bedrock-asset-processor` |
| Resource tag | `Project: karatu-2025-capstone` |
