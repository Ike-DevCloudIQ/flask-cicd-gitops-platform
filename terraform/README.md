# Stage 4 — Terraform Infrastructure as Code

> **Goal**: Provision a production-quality, multi-AZ AWS infrastructure for the Jenkins CI/CD platform using modular Terraform — remote state, segmented networking, locked-down security groups, IAM-attached EC2s, and CloudWatch monitoring.

---

## Table of Contents

1. [Why Terraform?](#1-why-terraform)
2. [Folder Structure Explained](#2-folder-structure-explained)
3. [Architecture Overview](#3-architecture-overview)
4. [Phase 1 — Bootstrap (Remote State)](#4-phase-1--bootstrap-remote-state)
5. [Phase 2 — Module: Network](#5-phase-2--module-network)
6. [Phase 3 — Module: Security](#6-phase-3--module-security)
7. [Phase 4 — Module: Compute](#7-phase-4--module-compute)
8. [Phase 5 — Module: Notifications](#8-phase-5--module-notifications)
9. [Phase 6 — Dev Environment Wiring](#9-phase-6--dev-environment-wiring)
10. [Variable Precedence & tfvars](#10-variable-precedence--tfvars)
11. [Remote State Deep Dive](#11-remote-state-deep-dive)
12. [Security Decisions Explained](#12-security-decisions-explained)
13. [Applied Outputs (Live Infrastructure)](#13-applied-outputs-live-infrastructure)
14. [Common Commands Reference](#14-common-commands-reference)
15. [Troubleshooting](#15-troubleshooting)
16. [Key Learnings](#16-key-learnings)

---

## 1. Why Terraform?

When you provision infrastructure manually (clicking through the AWS Console), you create **invisible, unrepeatable state**. You cannot:
- Recreate the exact environment after a disaster
- Diff what changed between last week and today
- Review infrastructure changes in a pull request
- Spin up an identical staging environment in 5 minutes

**Terraform solves this** by treating infrastructure as code — declarative HCL files that describe *what* you want, not *how* to build it. Terraform figures out the how.

**Core concepts every learner must understand:**

| Concept | What it means |
|---|---|
| **Provider** | Plugin that talks to a cloud API (AWS, Azure, GCP) |
| **Resource** | A single piece of infrastructure (EC2, SG, VPC) |
| **Module** | A reusable group of resources with inputs and outputs |
| **State file** | Terraform's memory — maps code to real cloud resources |
| **Plan** | A dry-run diff: what will be created, changed, or destroyed |
| **Apply** | Executes the plan against the real cloud |
| **Workspace** | Isolated state namespace for multiple environments |

---

## 2. Folder Structure Explained

```
terraform/
├── bootstrap/               # One-time: creates the S3 state bucket itself
│   ├── main.tf              # S3 bucket + versioning + encryption + public-access block
│   ├── providers.tf         # AWS + random providers
│   └── variables.tf         # project_name, aws_region, owner
│
├── modules/                 # Reusable building blocks (no environment-specific config)
│   ├── network/             # VPC, subnets, IGW, NAT, route tables
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/            # Security groups for master and slave
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/             # EC2 instances, IAM role, instance profile
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── notifications/       # SNS topic + CloudWatch alarms
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    └── dev/                 # Wires all modules together for the dev environment
        ├── backend.tf       # Remote state: S3 bucket + key + encryption
        ├── providers.tf     # AWS provider + default_tags
        ├── main.tf          # Calls all 4 modules, passes data between them
        ├── variables.tf     # All input variables with defaults and descriptions
        ├── outputs.tf       # Re-exports all useful module outputs
        ├── terraform.tfvars         # Real values (gitignored — never commit secrets)
        └── terraform.tfvars.example # Template for new developers
```

**Why this structure?**

- **bootstrap/** is applied *once* before anything else. It cannot reference the state bucket it creates (a chicken-and-egg problem) — so it stores its own state locally.
- **modules/** contain zero environment-specific values. They accept everything via variables. This makes them reusable: `source = "../../modules/network"` works from any environment.
- **environments/dev/** is the only place with real values. Adding a `prod/` folder would simply mean copying `dev/` and changing `environment = "prod"` and CIDR blocks.

---

## 3. Architecture Overview

```
                         ┌──────────────────────────────────────────────┐
                         │            AWS Region: eu-west-1             │
                         │                                              │
                         │  ┌──────────────────────────────────────┐   │
                         │  │       VPC: 10.0.0.0/16               │   │
                         │  │                                      │   │
  Internet ──────── IGW ─┼──┤  ┌─────────────────────────────┐    │   │
                         │  │  │  Public Subnet 10.0.1.0/24  │    │   │
                         │  │  │  AZ: eu-west-1a              │    │   │
                         │  │  │                             │    │   │
                         │  │  │  ┌──────────────────────┐   │    │   │
                         │  │  │  │  Jenkins Master      │   │    │   │
                         │  │  │  │  t3.medium            │   │    │   │
                         │  │  │  │  Public IP: 54.76.   │   │    │   │
                         │  │  │  │  201.117             │   │    │   │
                         │  │  │  └──────────────────────┘   │    │   │
                         │  │  │  ┌──────────────────────┐   │    │   │
                         │  │  │  │  NAT Gateway          │   │    │   │
                         │  │  │  └──────────┬───────────┘   │    │   │
                         │  │  └─────────────┼───────────────┘    │   │
                         │  │                │ private egress       │   │
                         │  │  ┌─────────────▼───────────────┐    │   │
                         │  │  │  Private Subnet 10.0.10.0/24│    │   │
                         │  │  │  AZ: eu-west-1b              │    │   │
                         │  │  │                             │    │   │
                         │  │  │  ┌──────────────────────┐   │    │   │
                         │  │  │  │  Jenkins Slave       │   │    │   │
                         │  │  │  │  t3.medium            │   │    │   │
                         │  │  │  │  Private IP: 10.0.10 │   │    │   │
                         │  │  │  │  .129                │   │    │   │
                         │  │  │  └──────────────────────┘   │    │   │
                         │  │  └─────────────────────────────┘    │   │
                         │  └──────────────────────────────────────┘   │
                         │                                              │
                         │  SNS Topic ──► CloudWatch Alarms (4 total)  │
                         └──────────────────────────────────────────────┘
```

**Traffic flow:**
- **Admin SSH**: `your-ip → IGW → Public Subnet → Master` (restricted to your IP only)
- **Jenkins UI**: `0.0.0.0/0 → IGW → Public Subnet → Master:8080`
- **Agent comms**: `Master → Private Subnet → Slave:50000` (JNLP — internal only)
- **Slave egress**: `Slave → NAT Gateway → IGW → Internet` (Docker Hub, GitHub, PyPI)

---

## 4. Phase 1 — Bootstrap (Remote State)

### The problem it solves

Terraform needs a place to store its state file — the JSON document that tracks every resource it manages. By default, Terraform saves state locally (`terraform.tfstate`) in the project folder.

**Local state is dangerous for teams because:**
- Two people applying simultaneously can corrupt state (race condition)
- If the file is deleted, Terraform loses track of what it created
- The file often contains sensitive data (passwords, IPs) and should never be committed to Git

**Solution: Remote state in S3** with native locking (`use_lockfile = true`).

### What bootstrap creates

```hcl
# main.tf (bootstrap)
resource "aws_s3_bucket" "tf_state" {
  bucket = local.state_bucket_name   # "flask-cicd-gitops-platform-tfstate-bd355f"
}
```

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | Stores all `.tfstate` files |
| `aws_s3_bucket_versioning` | Every state change is versioned — you can roll back |
| `aws_s3_bucket_server_side_encryption_configuration` | State is encrypted at rest (AES-256) |
| `aws_s3_bucket_public_access_block` | All 4 public access flags set to `true` — nobody can accidentally make state public |

### Why `random_id` in the bucket name?

```hcl
resource "random_id" "suffix" {
  byte_length = 3
}
```

S3 bucket names are **globally unique** across all AWS accounts worldwide. Appending a random 6-character hex suffix (`bd355f`) prevents name collisions. Without it, if anyone else ran this code with the same project name, the bucket creation would fail.

### Bootstrap apply — how to run it

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
# Outputs: tf_state_bucket_name = "flask-cicd-gitops-platform-tfstate-bd355f"
```

> **Important**: Bootstrap stores its own state locally. This is intentional — you cannot store state remotely before the remote state bucket exists. The `bootstrap/terraform.tfstate` file should be committed to Git or kept safe separately.

---

## 5. Phase 2 — Module: Network

### What it builds

12 resources that form the foundational network layer:

| Resource | Count | Purpose |
|---|---|---|
| `aws_vpc` | 1 | The isolated network boundary for all resources |
| `aws_internet_gateway` | 1 | Door to the internet for the VPC |
| `aws_subnet` (public) | 1 | 10.0.1.0/24 — eu-west-1a — Jenkins master lives here |
| `aws_subnet` (private) | 1 | 10.0.10.0/24 — eu-west-1b — Jenkins slave lives here |
| `aws_eip` | 1 | Static IP address assigned to the NAT gateway |
| `aws_nat_gateway` | 1 | Allows private subnet to reach internet (outbound only) |
| `aws_route_table` (public) | 1 | Routes 0.0.0.0/0 → IGW |
| `aws_route_table` (private) | 1 | Routes 0.0.0.0/0 → NAT |
| `aws_route` | 2 | Actual route entries in each table |
| `aws_route_table_association` | 2 | Binds each subnet to its route table |

**Total: 12 resources**

### Understanding public vs private subnets

The difference is **the route table**, not a special flag:

```
Public subnet route table:
  10.0.0.0/16  → local (traffic within VPC)
  0.0.0.0/0    → igw-xxxxxxxx  ← goes to internet directly

Private subnet route table:
  10.0.0.0/16  → local
  0.0.0.0/0    → nat-xxxxxxxx  ← goes to NAT, which goes to internet
```

The NAT gateway allows outbound internet (downloading packages, pushing to Docker Hub) from private instances, but **inbound connections from the internet are impossible**. There's no route back in.

### map_public_ip_on_launch

```hcl
resource "aws_subnet" "public" {
  map_public_ip_on_launch = true   # EC2s here get a public IP automatically
}

resource "aws_subnet" "private" {
  map_public_ip_on_launch = false  # EC2s here only have private IPs
}
```

### Multi-AZ design (why two AZs?)

| Zone | Subnet | What lives there |
|---|---|---|
| eu-west-1a | 10.0.1.0/24 (public) | Jenkins Master |
| eu-west-1b | 10.0.10.0/24 (private) | Jenkins Slave |

If AWS eu-west-1a has a datacenter incident, eu-west-1b is unaffected. The slave can still run builds. In a future scale-out, adding a second master in eu-west-1b is trivial.

### Module inputs and outputs

```hcl
# inputs (variables.tf)
variable "vpc_cidr"                  { default = "10.0.0.0/16" }
variable "public_subnet_cidr"        { default = "10.0.1.0/24" }
variable "private_subnet_cidr"       { default = "10.0.10.0/24" }
variable "public_availability_zone"  { default = "eu-west-1a" }
variable "private_availability_zone" { default = "eu-west-1b" }

# outputs (outputs.tf) — consumed by security and compute modules
output "vpc_id"             { value = aws_vpc.this.id }
output "public_subnet_id"   { value = aws_subnet.public.id }
output "private_subnet_id"  { value = aws_subnet.private.id }
```

---

## 6. Phase 3 — Module: Security

### What it builds

2 security groups with precisely scoped ingress rules:

#### Jenkins Master SG (`sg-0ba8a21cf4fa96779`)

| Direction | Port | Source | Reason |
|---|---|---|---|
| Ingress | 22 | Your IP only (`/32`) | SSH admin access — never open to the world |
| Ingress | 8080 | 0.0.0.0/0 | Jenkins web UI accessible publicly |
| Ingress | 443 | 0.0.0.0/0 | GitHub webhooks, HTTPS plugin downloads |
| Egress | All | 0.0.0.0/0 | Reach Docker Hub, GitHub, PyPI |

#### Jenkins Slave SG (`sg-03825bf81b347a521`)

| Direction | Port | Source | Reason |
|---|---|---|---|
| Ingress | 22 | Master SG ID | SSH from master only — bastion pattern |
| Ingress | 50000 | Master SG ID | JNLP agent communication |
| Egress | All | 0.0.0.0/0 | Outbound via NAT for builds |

### SG-to-SG references (critical concept)

```hcl
# slave SG references master SG by ID — not by IP address
ingress {
  security_groups = [aws_security_group.jenkins_master.id]
}
```

Why is this better than using an IP address? EC2 IPs can change on restart. Security group membership is stable and automatically updates when instances are replaced. The slave always allows traffic **from the master's security group**, regardless of what IP the master has.

### The `/32` principle for SSH

```hcl
# ✅ Correct: Only your specific IP can SSH to master
cidr_blocks = ["147.161.236.109/32"]

# ❌ Wrong: Anyone in the world can try to SSH
cidr_blocks = ["0.0.0.0/0"]
```

A `/32` CIDR means "exactly one IP address". Never open SSH to `0.0.0.0/0` on a production server — bots scan the entire internet for port 22 constantly.

---

## 7. Phase 4 — Module: Compute

### What it builds

| Resource | Purpose |
|---|---|
| `data.aws_ami` | Dynamically resolves the latest Amazon Linux 2023 AMI for the region |
| `aws_iam_role` | EC2 assumes this role — grants CloudWatch + SSM access |
| `aws_iam_role_policy_attachment` × 2 | Attaches AWS managed policies to the role |
| `aws_iam_instance_profile` | Binds the IAM role to EC2 instances |
| `aws_instance.jenkins_master` | Master in public subnet |
| `aws_instance.jenkins_slave` | Slave in private subnet |

### Dynamic AMI resolution

```hcl
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

**Why this matters**: If you hardcode an AMI ID like `ami-02d74237498939967`, it breaks the moment you change regions — AMI IDs are region-specific. The `data` block asks AWS "give me the latest Amazon Linux 2023 AMI in this region" at apply time. It always resolves correctly regardless of region.

### IAM role — least-privilege access

```hcl
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

Both policies are AWS-managed and grant:
- **CloudWatchAgentServerPolicy**: Allows the instance to push custom metrics and logs to CloudWatch
- **AmazonSSMManagedInstanceCore**: Allows AWS Systems Manager to connect to the instance — meaning you can open a shell session without opening port 22 at all

### EC2 storage — gp3 encrypted

```hcl
root_block_device {
  volume_type = "gp3"      # 3000 IOPS baseline free (vs gp2: 100 IOPS/GB)
  volume_size = 30         # 30GB — enough for Jenkins workspace + Docker images
  encrypted   = true       # AES-256 encryption at rest
}
```

**gp3 vs gp2**: gp3 gives you 3,000 IOPS and 125 MB/s throughput by default at no extra cost, while gp2 scales IOPS with size (a 30GB gp2 gets only 100 IOPS). gp3 is almost always cheaper and faster.

### Minimal user_data — Ansible does the rest

```bash
#!/bin/bash
yum update -y
hostnamectl set-hostname jenkins-master
```

The user_data only handles two things:
1. Apply system updates at first boot
2. Set hostname so Ansible can identify the node

**Everything else** (installing Jenkins, Java, Docker, plugins) is handled by Ansible in Stage 5. This separation of concerns means you can re-run Ansible without destroying and rebuilding the EC2.

---

## 8. Phase 5 — Module: Notifications

### What it builds

| Resource | Count | Purpose |
|---|---|---|
| `aws_sns_topic` | 1 | Central pub/sub bus for all alerts |
| `aws_sns_topic_subscription` | 1 | Email endpoint — receives all alarms |
| `aws_cloudwatch_metric_alarm` | 4 | CPU (master + slave) + StatusCheck (master + slave) |

### SNS (Simple Notification Service) pattern

```
CloudWatch Alarm (CPU > 80%) ──► SNS Topic ──► Email Subscription
CloudWatch Alarm (Status Check) ──► SNS Topic ──┘
```

All alarms publish to a single topic. You can add more subscribers later (Slack webhook, PagerDuty, Lambda) by adding subscriptions to the same topic — without changing any alarm configuration.

### CloudWatch alarm anatomy

```hcl
resource "aws_cloudwatch_metric_alarm" "master_cpu_high" {
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2      # Must breach threshold for 2 consecutive periods
  period              = 120    # Each period is 120 seconds
  threshold           = 80     # 80% CPU utilization
  statistic           = "Average"
}
```

**evaluation_periods × period = alert delay**: `2 × 120s = 4 minutes` of sustained high CPU before alerting. This prevents false alarms from short spikes during Jenkins builds.

**ok_actions**: When CPU drops back below 80%, a recovery notification is sent — so you know the issue resolved itself.

> **Action required after first apply**: Check your email (`mraustin2ik@gmail.com`) for an AWS SNS subscription confirmation. You must click the link to activate email delivery.

---

## 9. Phase 6 — Dev Environment Wiring

### How modules chain together

```
main.tf (environments/dev)
│
├── module "network" ───────────────────────────────────────────────────►  outputs vpc_id, subnet IDs
│                                                                              │
├── module "security" ◄── vpc_id ────────────────────────────────────────────┘
│                                                                              │
├── module "compute"  ◄── public_subnet_id, private_subnet_id, master_sg_id, slave_sg_id
│                                                                              │
└── module "notifications" ◄── master_instance_id, slave_instance_id ────────┘
```

The key pattern is **module output → module input**:

```hcl
# network runs first, produces VPC and subnet IDs
module "network" {
  source = "../../modules/network"
}

# security consumes network output
module "security" {
  vpc_id = module.network.vpc_id         # ← output from network module
}

# compute consumes outputs from both network and security
module "compute" {
  public_subnet_id  = module.network.public_subnet_id
  master_sg_id      = module.security.jenkins_master_sg_id
}

# notifications consumes instance IDs from compute
module "notifications" {
  master_instance_id = module.compute.jenkins_master_instance_id
}
```

Terraform automatically infers the dependency graph from these references and creates resources in the correct order.

### Backend configuration

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket       = "flask-cicd-gitops-platform-tfstate-bd355f"
    key          = "environments/dev/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true   # S3 native locking — no DynamoDB needed (Terraform 1.10+)
  }
}
```

The `key` acts like a file path inside the bucket. If you add `environments/prod/`, it would use `environments/prod/terraform.tfstate` — completely isolated state.

### Providers with default_tags

```hcl
provider "aws" {
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}
```

Every single AWS resource created in this environment automatically inherits these 4 tags. You don't need to repeat them in every resource block. This makes cost allocation, compliance filtering, and resource discovery effortless.

---

## 10. Variable Precedence & tfvars

Terraform resolves variable values in this priority order (highest wins):

```
1. -var flag on CLI           terraform apply -var="key_name=my-key"
2. -var-file flag on CLI      terraform apply -var-file="custom.tfvars"
3. terraform.tfvars           (auto-loaded if present)
4. *.auto.tfvars              (auto-loaded alphabetically)
5. Environment variables      TF_VAR_key_name=my-key
6. Default values in code     variable "key_name" { default = "..." }
7. Interactive prompt          (if no default and not set anywhere)
```

In this project, `terraform.tfvars` provides all values. Variables **without** a default (`your_ip_cidr`, `key_name`, `alert_email`) will cause an error if not set in tfvars — this is intentional. They are environment-specific and must be set explicitly.

### What to never commit

```
# .gitignore entries for terraform
terraform.tfvars          # Contains your real IP and email
*.pem                     # SSH key files
.terraform/               # Provider binaries (100MB+ — reinstalled via terraform init)
*.tfstate                 # State files for environments (not bootstrap)
tfplan                    # Binary plan files
```

The `terraform.tfvars.example` file **is** committed — it documents what values are needed without exposing the real ones.

---

## 11. Remote State Deep Dive

### State locking

When `terraform apply` starts, it writes a lock file to S3:

```
s3://flask-cicd-gitops-platform-tfstate-bd355f/
  environments/dev/terraform.tfstate          # State file
  environments/dev/terraform.tfstate.tflock   # Lock file (Terraform 1.10+ native)
```

If a second `terraform apply` tries to run simultaneously:
```
Error: Error acquiring the state lock
  Lock Info:
    ID:        abc123...
    Operation: OperationTypeApply
    Who:       user@machine
```

This prevents two people (or two CI/CD runs) from corrupting state simultaneously.

### Versioning — your rollback mechanism

S3 versioning was enabled in bootstrap:
```hcl
versioning_configuration {
  status = "Enabled"
}
```

Every state change creates a new version. To recover from a bad apply:
```bash
# List all state versions
aws s3api list-object-versions \
  --bucket flask-cicd-gitops-platform-tfstate-bd355f \
  --prefix environments/dev/terraform.tfstate

# Restore a previous version by ID
aws s3api copy-object \
  --bucket flask-cicd-gitops-platform-tfstate-bd355f \
  --copy-source "flask-cicd-gitops-platform-tfstate-bd355f/environments/dev/terraform.tfstate?versionId=PREVIOUS_VERSION_ID" \
  --key environments/dev/terraform.tfstate
```

---

## 12. Security Decisions Explained

| Decision | Why |
|---|---|
| SSH restricted to `/32` CIDR | Bots scan all internet IPs for port 22 24/7. Restricting to your IP reduces attack surface to near zero. |
| Slave in private subnet | The slave never needs direct internet inbound. NAT handles outbound. This eliminates a whole class of ingress attacks. |
| SG-to-SG references for slave | More resilient than IP-based rules. Works even if master's IP changes. |
| IAM role instead of access keys | Never put AWS credentials on an EC2. The IAM role is automatically rotated and scoped to only what the instance needs. |
| SSM policy on EC2 | You can open a browser-based shell session via AWS Console without any open SSH port — a secondary access path if your IP changes. |
| Root volume encryption | Encrypts all data at rest including swap, temp files, and any secrets Jenkins writes to disk. |
| gp3 over gp2 | Better performance at lower cost. Security and performance are not tradeoffs here. |
| S3 public access block (all 4 flags) | Prevents any future misconfigured bucket policy or ACL from accidentally making state public. Defense in depth. |
| AES-256 for state bucket | State files can contain resource IDs, IP addresses, and other sensitive data. Encryption at rest is essential. |

---

## 13. Applied Outputs (Live Infrastructure)

These are the actual AWS resource IDs from the successful apply on 2026-06-23:

```
ami_id_used              = "ami-02d74237498939967"   # Amazon Linux 2023, eu-west-1
internet_gateway_id      = "igw-00fa7174af9d1995f"
jenkins_master_public_ip = "54.76.201.117"            # SSH target for Ansible
jenkins_master_sg_id     = "sg-0ba8a21cf4fa96779"
jenkins_slave_private_ip = "10.0.10.129"              # Reached via master as bastion
jenkins_slave_sg_id      = "sg-03825bf81b347a521"
nat_gateway_id           = "nat-0290c1c791899af23"
private_subnet_id        = "subnet-0bb23643909013d53"
public_subnet_id         = "subnet-06672d5b2905cf9b6"
sns_topic_arn            = "arn:aws:sns:eu-west-1:184353012435:flask-cicd-gitops-platform-dev-alerts"
vpc_id                   = "vpc-018857fa46aa6659c"
```

To retrieve these at any time:
```bash
cd terraform/environments/dev
terraform output
```

---

## 14. Common Commands Reference

### Full workflow (first time)

```bash
# 1. Bootstrap — create state bucket (run once ever)
cd terraform/bootstrap
terraform init
terraform apply

# 2. Dev environment — first run
cd terraform/environments/dev
terraform init                    # Downloads providers, configures S3 backend
terraform plan -out tfplan        # Dry-run, save plan to file
terraform apply tfplan            # Apply exactly what was planned

# 3. View outputs
terraform output

# 4. SSH to master
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem ec2-user@54.76.201.117

# 5. SSH to slave (via master as bastion)
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem \
    -J ec2-user@54.76.201.117 \
    ec2-user@10.0.10.129
```

### Day-to-day operations

```bash
# Check what will change before applying
terraform plan

# Apply only a specific module
terraform apply -target=module.compute

# Destroy all infrastructure (careful — irreversible)
terraform destroy

# Destroy only a specific resource
terraform destroy -target=aws_instance.jenkins_master

# Import an existing resource into state
terraform import aws_instance.jenkins_master i-0abc123def456789

# Refresh state from real AWS (detect drift)
terraform refresh

# View state contents
terraform state list
terraform state show module.network.aws_vpc.this

# Remove a resource from state (without destroying it)
terraform state rm module.compute.aws_instance.jenkins_master

# Format all .tf files consistently
terraform fmt -recursive

# Validate syntax and config
terraform validate
```

### Debugging

```bash
# Enable verbose logging
TF_LOG=DEBUG terraform apply 2>&1 | tee terraform-debug.log

# Check provider version lock
cat .terraform.lock.hcl

# Re-initialize after provider changes
terraform init -upgrade
```

---

## 15. Troubleshooting

### "The key pair 'xxx' does not exist"

```
Error: InvalidKeyPair.NotFound
```

**Cause**: `key_name` in `terraform.tfvars` doesn't match an existing key pair in your AWS account.  
**Fix**: Check the key pair name in `AWS Console → EC2 → Key Pairs`, then update `terraform.tfvars`.

### "Error acquiring the state lock"

```
Error: Error acquiring the state lock
```

**Cause**: A previous apply crashed without releasing the lock.  
**Fix**:
```bash
terraform force-unlock LOCK_ID
```
Find the LOCK_ID in the error output or:
```bash
aws s3api list-objects --bucket flask-cicd-gitops-platform-tfstate-bd355f \
  --query "Contents[?contains(Key, '.tflock')]"
```

### "NoCredentialsError" or "AuthFailure"

```
Error: No valid credential sources found
```

**Fix**: Ensure AWS CLI is configured:
```bash
aws sts get-caller-identity   # Should return your account ID
aws configure                  # Re-enter credentials if needed
```

### "Error: Backend configuration changed"

```
Error: Backend initialization required, please run "terraform init"
```

**Cause**: `backend.tf` was changed after last `terraform init`.  
**Fix**: `terraform init -reconfigure`

### EC2 instance stuck in "pending"

```bash
# Check EC2 system logs
aws ec2 get-console-output --instance-id i-XXXXXXXXXXXXXXXXX --region eu-west-1
```

### Terraform plan shows unexpected destroy

Before applying any plan that shows destroys, read it carefully. Common causes:
- Variable value changed (e.g., `your_ip_cidr` changed → security group recreated)
- AMI resolved to a new version → EC2 replacement required
- Resource has a `lifecycle { create_before_destroy = true }` — it creates new first, then destroys old

---

## 16. Key Learnings

### For beginners

1. **Terraform is declarative, not imperative.** You describe the end state, not the steps. `resource "aws_instance" "x"` means "ensure this exists", not "create this now".

2. **Always plan before apply.** `terraform plan -out tfplan` followed by `terraform apply tfplan` guarantees you apply exactly what you reviewed. Never `terraform apply` without reviewing a plan first.

3. **The state file is sacred.** It's how Terraform knows what it manages. If it's lost or corrupted, Terraform cannot manage your infrastructure. Store it remotely, enable versioning, never edit it manually.

4. **Modules are functions.** They take inputs (variables) and return outputs. You call them like `module "network" { ... }`. The folder is the module.

5. **`depends_on` vs implicit dependency.** When resource B references `resource_a.id`, Terraform automatically knows B depends on A. `depends_on` is only needed when the dependency isn't in the code (e.g., a NAT gateway that must exist before an EIP is usable).

### For intermediate learners

6. **Remote state unlocks team workflows.** Multiple engineers can run Terraform safely because state locking prevents concurrent applies. State versioning provides rollback. Shared state allows cross-stack data sharing via `terraform_remote_state` data source.

7. **`data` sources vs `resource` blocks.** A `data` source reads existing infrastructure (or AWS metadata) — it creates nothing. A `resource` block creates and manages infrastructure. The dynamic AMI lookup (`data "aws_ami"`) is a perfect example of using data sources to avoid hardcoding region-specific values.

8. **Tagging strategy.** `default_tags` in the provider block means every resource gets `Project`, `Environment`, `Owner`, `ManagedBy` automatically. This is foundational for cost allocation, compliance, and operations.

9. **Module output chaining.** `module.network.vpc_id` passes the VPC ID from the network module to the security module. Terraform builds a DAG (directed acyclic graph) of dependencies and provisions in the correct order — no manual sequencing required.

### For advanced learners

10. **Why not DynamoDB for locking?** Terraform 1.10+ supports native S3 locking via `use_lockfile = true`. This writes a `.tflock` file alongside the state file. It eliminates the need for a separate DynamoDB table (and its IAM permissions, costs, and operational overhead).

11. **Workspaces vs directories for environments.** This project uses separate directories (`environments/dev/`, `environments/prod/`). An alternative is Terraform workspaces (`terraform workspace new prod`). Directories are preferred for significant environment differences because they allow separate `providers.tf`, `backend.tf`, and variable defaults. Workspaces share all code and only separate state — suitable for nearly-identical environments.

12. **`terraform import` for brownfield.** If your team already has existing infrastructure, you can bring it under Terraform management with `terraform import`. The resource stays unchanged; Terraform just starts tracking it in state.

---

*Stage 4 complete. Next: [Stage 5 — Ansible Configuration Management](../ansible/README.md)*

## 👤 Author

**Ikenna Ubah** — DevOps & Platform Engineer

[![GitHub](https://img.shields.io/badge/GitHub-Ike--DevCloudIQ-181717?logo=github)](https://github.com/Ike-DevCloudIQ)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ikenna%20Ubah-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ikenna2/)

> ⭐ If you found this project useful or insightful, please consider starring the repository.
