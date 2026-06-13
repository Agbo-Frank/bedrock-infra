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
    │  RDS MySQL  │  │  RDS PgSQL  │ │    Redis    │
    └─────────────┘  └──────┬──────┘ └─────────────┘
                            │
                     ┌──────▼──────┐
                     │  RabbitMQ   │
                     └─────────────┘
                                      ┌──────▼──────┐
                                      │    carts    │
                                      │ (Java/DDB)  │
                                      └──────┬──────┘
                                      ┌──────▼──────┐
                                      │  DynamoDB   │
                                      └─────────────┘
```

**AWS services used:**


| Service             | Purpose                                                      |
| ------------------- | ------------------------------------------------------------ |
| EKS Auto Mode       | Kubernetes cluster (manages nodes, load balancer controller) |
| RDS MySQL           | Catalog service database                                     |
| RDS PostgreSQL      | Orders service database                                      |
| DynamoDB            | Cart service (items per user)                                |
| S3                  | Static product image assets                                  |
| Lambda (Node.js)    | Processes S3 upload events                                   |
| Secrets Manager     | RDS passwords (auto-generated)                               |
| CloudWatch          | Logs via Fluent Bit DaemonSet (EKS add-on)                   |
| GitHub Actions OIDC | CI/CD — no long-lived credentials stored                     |


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
├── helm/                     # Upstream retail-store-sample charts (Bonus 5.1)
│   ├── retail-store/         # Umbrella chart
│   ├── cart/                 # DynamoDB via IRSA
│   ├── catalog/              # External MySQL (RDS)
│   ├── checkout/             # In-cluster Redis
│   ├── orders/               # External Postgres (RDS) + in-cluster RabbitMQ
│   ├── ui/                   # Frontend + ALB ingress
│   ├── values.yaml           # Static overrides (committed)
│   └── values.generated.yaml # RDS endpoints, IRSA, passwords (gitignored)
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
│       ├── main.sh           # Entry point: configure | helm | all
│       ├── configure.sh
│       └── helm.sh
└── .github/workflows/
    ├── terraform-plan.yml    # runs on PR → posts plan as comment
    └── terraform-apply.yml   # runs on merge to main → applies
```

---

## Prerequisites

Install these tools before running anything:


| Tool      | Minimum version | Install                  |
| --------- | --------------- | ------------------------ |
| Terraform | 1.5.0           | `brew install terraform` |
| AWS CLI   | v2              | `brew install awscli`    |
| kubectl   | 1.28+           | `brew install kubectl`   |
| Helm      | 3.12+           | `brew install helm`      |
| jq        | any             | `brew install jq`        |


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

### 3. Configure Terraform variables

Copy the example tfvars file and fill in your values:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Get your IAM user ARN (used for EKS cluster admin access):

```bash
aws sts get-caller-identity --query Arn --output text
```

Edit `terraform/terraform.tfvars` and set:

```hcl
github_username = "your-actual-github-username"
admin_arn       = "arn:aws:iam::ACCOUNT_ID:user/YOUR_IAM_USER"
```

> `terraform.tfvars` is gitignored — do not commit it.
> In CI, `github_username` is auto-populated from `github.repository_owner`.
> `admin_arn` can be set as the `ADMIN_ARN` repository secret in GitHub Actions (falls back to `AWS_ROLE_ARN` if unset).

### 4. Create your GitHub repository

Create a repo named `bedrock-infra` on GitHub (the OIDC trust policy is scoped to this exact name), then push this code:

```bash
git remote add origin git@github.com:YOUR_GITHUB_USERNAME/bedrock-infra.git
git push -u origin main
```

### 5. Add the GitHub secret (after first apply)

After running `terraform apply`, add `AWS_ROLE_ARN` to your GitHub repo secrets:

```
GitHub repo → Settings → Secrets and variables → Actions → New repository secret
Name:  AWS_ROLE_ARN
Value: <output from terraform: github_oidc_role_arn>
```

### 6. Commit grading output (after first apply)

`terraform apply` writes two files at the repo root:

| File | Commit to GitHub? | Contents |
|------|-------------------|----------|
| `grading.json` | Yes | Non-sensitive outputs (cluster name, endpoints, ARNs) |
| `grading.credentials.json` | **Never** | Sensitive dev credentials — gitignored automatically |

```bash
git add grading.json
git commit -m "Add terraform grading outputs"
git push
```

Share `grading.credentials.json` with your grader privately (email/LMS), not via GitHub. Push protection will block AWS keys in git history.

---

## Deployment

### Full deployment (first time)

```bash
./scripts/deploy.sh
```

This runs everything end-to-end:

1. `terraform apply` — provisions all AWS infrastructure (~15-20 min)
2. Generates `helm/values.generated.yaml` (RDS endpoints, IRSA ARN, DB passwords) and `grading.json`
3. `aws eks update-kubeconfig` — points kubectl at the new cluster
4. `helm upgrade --install` — deploys the upstream retail-store chart with RDS/DynamoDB overrides

After the first apply, commit `grading.json` (see one-time setup step 6) and add the `AWS_ROLE_ARN` GitHub secret (step 5) to enable CI/CD.

### Step-by-step (recommended when learning)

```bash
# 1. Preview what terraform will create
./scripts/terraform/main.sh plan

# 2. Apply infrastructure (also generates helm/values.generated.yaml and grading.json)
./scripts/terraform/main.sh apply

# Commit grading.json for the capstone grader (never commit grading.credentials.json)
git add grading.json && git commit -m "Add terraform grading outputs" && git push

# 3. Configure kubectl
./scripts/k8s/main.sh configure

# 4. Deploy via Helm (RDS endpoints, IRSA, and DB passwords injected automatically)
./scripts/k8s/main.sh helm
```

### Helm deploy (single command)

After `terraform apply`:

```bash
./scripts/k8s/main.sh configure
./scripts/k8s/main.sh helm
```

Or run Helm directly (requires `helm/values.generated.yaml` from the script above):

```bash
helm dependency update ./helm/retail-store

helm upgrade --install retail-app ./helm/retail-store \
  -f ./helm/values.yaml \
  -f ./helm/values.generated.yaml \
  -n retail-app --create-namespace
```

`values.generated.yaml` is created automatically by `helm.sh`. It contains RDS endpoints, the cart IRSA ARN, and DB passwords from Secrets Manager. It is gitignored and must not be committed.

**Managed AWS data layer overrides** (in `helm/values.yaml`):

| Service | In-cluster default | This project |
|---------|-------------------|--------------|
| Catalog | MySQL pod | RDS MySQL |
| Orders | PostgreSQL pod | RDS PostgreSQL |
| Cart | DynamoDB local / in-memory | DynamoDB (`Items`) via IRSA |
| Checkout | — | In-cluster Redis |
| Orders messaging | — | In-cluster RabbitMQ |

### Re-deploy k8s only (terraform already applied)

```bash
./scripts/deploy.sh --k8s-only
```

> **Note:** If the `retail-app` namespace exists from a previous kubectl-based deploy but has no Helm release, `helm.sh` will delete that namespace before installing. This is intentional — it prevents stale ConfigMaps from conflicting with the Helm-managed release.

### Verify deployment

After Helm finishes, confirm pods are healthy (catalog and orders may take ~1 min to pass readiness probes):

```bash
kubectl get pods -n retail-app
kubectl rollout status deployment/catalog -n retail-app --timeout=180s
kubectl rollout status deployment/orders -n retail-app --timeout=180s
kubectl get ingress -n retail-app
```

All pods should reach `1/1 Running` before opening the app URL.

---

## Accessing the application

After deployment, get the ALB address:

```bash
kubectl get ingress -n retail-app
```

The `ADDRESS` column shows the ALB DNS name. It takes ~2 minutes for the ALB to be provisioned after the Ingress is created.

```
NAME   CLASS   HOSTS   ADDRESS                                          PORTS
ui     alb     *       k8s-retailapp-xxx.us-east-1.elb.amazonaws.com   80
```

Open `http://<ADDRESS>` in a browser.

---

## CI/CD pipeline

The GitHub Actions workflows in `.github/workflows/` automate **infrastructure changes** (Terraform only). Kubernetes/Helm deployment is run locally via `./scripts/deploy.sh` or `./scripts/k8s/main.sh all`.


| Event                  | Workflow              | What it does                                               |
| ---------------------- | --------------------- | ---------------------------------------------------------- |
| Pull request to `main` | `terraform-plan.yml`  | Runs `terraform plan` and posts the output as a PR comment |
| Merge to `main`        | `terraform-apply.yml` | Runs `terraform apply` automatically                       |


Authentication uses OIDC — GitHub never stores AWS access keys. The `AWS_ROLE_ARN` secret must be set (see one-time setup step 5). Review the plan comment carefully before merging — `terraform apply` makes real changes to live infrastructure.

---

## Useful commands

```bash
# Pod status
kubectl get pods -n retail-app
kubectl get pods -n retail-app -w          # watch live

# All resources + ingress
kubectl get all -n retail-app
kubectl get ingress -n retail-app

# Helm release
helm list -n retail-app
helm status retail-app -n retail-app

# Logs (deployment names from upstream chart)
kubectl logs -n retail-app deploy/carts -f
kubectl logs -n retail-app deploy/catalog -f
kubectl logs -n retail-app deploy/orders -f
kubectl logs -n retail-app deploy/checkout -f
kubectl logs -n retail-app deploy/ui -f

# Previous crash logs
kubectl logs -n retail-app deploy/carts --previous

# Debug a pod
kubectl describe pod -n retail-app <pod-name>

# Nodes (EKS Auto Mode provisions on demand)
kubectl get nodes
```

---

## Terraform outputs

After `terraform apply`, these outputs are available:

```bash
terraform -chdir=terraform output
```


| Output                  | Description                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------- |
| `cluster_name`          | EKS cluster name (`project-bedrock-cluster`)                                        |
| `cluster_endpoint`      | Kubernetes API server URL                                                           |
| `region`                | AWS region                                                                          |
| `vpc_id`                | VPC ID                                                                              |
| `assets_bucket_name`    | S3 bucket for product images                                                        |
| `cart_irsa_role_arn`    | IAM role ARN for the cart ServiceAccount (`cart-sa`)                                |
| `github_oidc_role_arn`  | IAM role ARN for GitHub Actions — set as `AWS_ROLE_ARN` repo secret                 |
| `mysql_endpoint`        | RDS MySQL hostname:port for catalog                                                 |
| `postgres_endpoint`     | RDS PostgreSQL hostname:port for orders                                             |
| `dev_console_password`  | Initial AWS Console password for `bedrock-dev-view` — share with grader (sensitive) |
| `dev_access_key_id`     | Access Key ID for `bedrock-dev-view` — share with grader                            |
| `dev_secret_access_key` | Secret Access Key for `bedrock-dev-view` — share with grader (sensitive)            |


---

## Tearing down

```bash
# Remove Kubernetes resources first
helm uninstall retail-app -n retail-app

# Destroy AWS infrastructure
./scripts/terraform/main.sh destroy
```

You will be prompted to type `yes` to confirm. This destroys all AWS resources managed by Terraform. The Terraform state S3 bucket is not deleted — remove it manually if needed.

---

## Grading constraints


| Constraint           | Value                             |
| -------------------- | --------------------------------- |
| EKS cluster name     | `project-bedrock-cluster`         |
| VPC name             | `project-bedrock-vpc`             |
| Kubernetes namespace | `retail-app`                      |
| IAM user             | `bedrock-dev-view`                |
| S3 assets bucket     | `bedrock-assets-alt-soe-025-4161` |
| Lambda function      | `bedrock-asset-processor`         |
| Resource tag         | `Project: karatu-2025-capstone`   |


