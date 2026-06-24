# Stage 5 - Ansible Configuration Management (Complete)

This stage configures the Terraform-provisioned Jenkins infrastructure end-to-end with dynamic inventory, role-based configuration, and service validation.

## Stage Goal

Automate post-provision EC2 configuration so Jenkins master and Jenkins slave are reproducible, idempotent, and ready for Stage 6 CI pipeline setup.

## Stage Inputs (from Terraform Stage 4)

- Jenkins master public IP: 54.76.201.117
- Jenkins slave private IP: 10.0.10.129
- Region: eu-west-1
- EC2 tags used for discovery:
  - Project=flask-cicd-gitops-platform
  - Environment=dev
  - Role=jenkins-master or jenkins-slave

## What Was Implemented

### 1) Control Plane Configuration

Files:
- ansible.cfg
- requirements.yml

Implemented:
- Dynamic inventory plugin enablement (amazon.aws.aws_ec2)
- Stable output formatting and callback compatibility for modern ansible-core
- SSH behavior and interpreter defaults

### 2) Dynamic Inventory and Host Grouping

Files:
- inventory/aws_ec2.yml
- inventory/group_vars/all.yml
- inventory/group_vars/jenkins_master.yml
- inventory/group_vars/jenkins_slave.yml

Implemented:
- Runtime host discovery from AWS APIs
- Group mapping to jenkins_master and jenkins_slave by Role tag
- Host selection by IP addresses
- Bastion/proxy SSH path from control machine to private slave via master

### 3) Role-Based Provisioning

Files:
- roles/common/tasks/main.yml
- roles/docker/tasks/main.yml
- roles/java/tasks/main.yml
- roles/jenkins-master/tasks/main.yml
- roles/jenkins-slave/tasks/main.yml
- playbooks/site.yml

Implemented:
- Baseline OS packages, updates, and time sync
- Docker installation and group management
- Java runtime installation and default JVM selection
- Jenkins repository setup and package installation
- Jenkins service bootstrap and readiness wait
- Jenkins slave user/workdir preparation

## Detailed Step-by-Step Execution Flow

### Step 0 - Prepare the Control Node

1. Ensure AWS identity is valid:

```bash
aws sts get-caller-identity
```

2. Install Ansible and dependencies:

```bash
brew install ansible
python3 -m pip install --break-system-packages boto3 botocore
```

3. Install required collection:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### Step 1 - Verify Discovery Before Configuration

```bash
ansible-inventory -i inventory/aws_ec2.yml --graph
```

Expected result:
- one host in jenkins_master
- one host in jenkins_slave

### Step 2 - Verify Network Reachability

```bash
ansible -i inventory/aws_ec2.yml all -m ping
```

Expected result:
- both hosts return pong

### Step 3 - Apply Configuration

```bash
ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml
```

Playbook phases:
1. Baseline on both hosts: common + docker + java
2. Master only: jenkins-master role
3. Slave only: jenkins-slave role

### Step 4 - Verify Jenkins Service and UI

1. Endpoint check:

```bash
curl -I http://54.76.201.117:8080/login
```

2. First-time unlock password:

```bash
ssh -i ~/.ssh/flask-cicd-gitops-dev-key.pem -o StrictHostKeyChecking=no ec2-user@54.76.201.117 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
```

## Issues Encountered and Fixes Applied

### Issue A - ansible-inventory command missing

Cause:
- Running in environment where Ansible binaries were not on PATH.

Fix:
- Installed Ansible via Homebrew and verified binary path.

### Issue B - Inventory host resolution failures

Cause:
- Inventory initially resolved hostnames not reachable by DNS.

Fix:
- Updated inventory host resolution to use IP addresses for active hosts.

### Issue C - SSH timeout to master and slave

Cause:
- Master SSH ingress did not match current admin public IP.

Fix:
- Updated security group ingress on port 22 to current source IP and validated SSH.

### Issue D - Amazon Linux curl package conflict

Cause:
- Installing curl conflicted with curl-minimal on AL2023.

Fix:
- Removed curl from base package list in group_vars/all.yml.

### Issue E - Jenkins package GPG signature mismatch

Cause:
- Upstream key/signature mismatch at install time.

Fix:
- Kept repo endpoint aligned with current package source and disabled gpgcheck as temporary unblock for this stage.

### Issue F - Jenkins service failed after install

Cause:
- Installed Jenkins required Java 21 but service started with Java 17.

Fix:
- Installed java-21-amazon-corretto-headless
- Set Java 21 as default alternative
- Added systemctl reset-failed guard for stable startup behavior

## Final Validation Evidence

- ansible-inventory graph showed both hosts and both groups
- ansible ping returned success on both hosts
- playbook completed with failed=0 unreachable=0
- Jenkins login endpoint returned HTTP 200
- Jenkins initial admin password successfully retrieved

## Resulting Host State

### Jenkins Master

- Docker installed and running
- Java 21 default runtime
- Jenkins installed and running
- Jenkins listening on port 8080

### Jenkins Slave

- Docker installed and running
- Java runtime present
- jenkins user and /opt/jenkins-agent created
- Reachable through bastion path

## Security Notes and Required Cleanup

1. Restrict SSH ingress on master SG back to current admin /32 if temporarily broadened during recovery.
2. Re-enable Jenkins repository gpgcheck once upstream signing mismatch is resolved.
3. Consider replacing ad-hoc SSH with AWS SSM for management-plane access.

## Stage 5 Completion Criteria Checklist

- Dynamic inventory discovers EC2 hosts by tags
- Grouping into jenkins_master and jenkins_slave is correct
- SSH path works for both hosts (direct to master, proxied to slave)
- Provisioning is idempotent across repeated playbook runs
- Jenkins service is active
- Jenkins UI is reachable at:

```text
http://54.76.201.117:8080/login
```

Stage 5 status: Completed.

## Transition to Stage 6

With Stage 5 complete, Stage 6 can begin:

1. Jenkins credentials setup (GitHub, Docker Hub)
2. Jenkins pipeline definition (Jenkinsfile)
3. Shared library implementation (build, scan, push, manifest update)
4. First CI run and artifact promotion flow

## 👤 Author

**Ikenna Ubah** — DevOps & Platform Engineer

[![GitHub](https://img.shields.io/badge/GitHub-Ike--DevCloudIQ-181717?logo=github)](https://github.com/Ike-DevCloudIQ)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Ikenna%20Ubah-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ikenna2/)

> ⭐ If you found this project useful or insightful, please consider starring the repository.