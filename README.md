# AWS EKS Deployment

## Overview

This project demonstrates an end-to-end, production-style **cloud-native DevOps workflow** on AWS using Kubernetes.  
It showcases infrastructure automation, CI/CD, GitOps, observability, and environment separation following real-world best practices.

The core application is a containerized Python (Flask) service deployed to **Amazon EKS** using **Helm**, with infrastructure provisioned via **Terraform** and automated delivery using **Jenkins**, **GitHub Actions**, and **Argo CD**.

---

## Architecture Summary

**Core components:**
- **Terraform** for infrastructure provisioning (modular, remote state, locking)
- **Amazon EKS** for Kubernetes orchestration
- **Amazon ECR** for container image storage
- **Helm** for Kubernetes application packaging
- **Jenkins** for CI/CD (build → push → deploy)
- **GitHub Actions + Argo CD** for GitOps-based delivery
- **Prometheus & Grafana** for monitoring and alerting

**Environment separation:**
- `dev` and `prod` use **separate Terraform state files**
- Separate **EKS clusters**, **ALBs**, and **Argo CD Applications**
- Shared Helm chart to maintain configuration parity

---

## Repository Structure

```text
.
├── app/                    # Flask application source
│   └── hello-python/
├── terraform/
│   ├── modules/            # Reusable Terraform modules
│   │   ├── vpc/
│   │   ├── eks/
│   │   ├── node-group/
│   │   ├── ecr/
│   │   └── jenkins-ec2/
│   └── envs/
│       ├── dev/
│       └── prod/
├── helm/
│   └── hello-python/       # Helm chart for the app
├── argocd/                 # Argo CD Applications
├── monitoring/             # ServiceMonitors & dashboards
├── Jenkinsfile             # Jenkins CI/CD pipeline
└── README.md
```
## Prerequisites

- **AWS account** with appropriate IAM permissions
- **AWS CLI** configured (`aws configure`)
- **Terraform** ≥ 1.5
- **kubectl** (Kubernetes CLI)
- **Helm** (Kubernetes package manager)
- **Docker**
- **GitHub account**

## Getting Started (Clone the Repository)

Clone the repository locally:

```bash
git clone https://github.com/luchenzo7/EKS_Deployment.git
cd EKS_Deployment
```
Ensure you are working from the repository root before proceeding.
## Environment Setup (DEV)

### 1. Initialize Terraform Backend

Terraform uses:

- **S3** for remote state
- **DynamoDB** for state locking

```bash
cd terraform/envs/dev
terraform init
```
### 2. Provision Infrastructure

Creates:

- **VPC**
- **EKS cluster**
- **Managed node group**
- **ECR repository**

```bash
terraform plan
terraform apply
```
### 3. Configure kubectl

Update your local kubeconfig to connect to the EKS cluster:

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name tc2-dev-eks
```
Verify cluster connectivity:
```bash
kubectl get nodes
```

## Application Deployment (DEV)
### 1. Build & Push Image to ECR
```bash
docker build -t hello-python .
docker tag hello-python:latest <ECR_URI>:latest
docker push <ECR_URI>:latest
```
### 2. Deploy via Helm
```bash
kubectl create namespace hello-python
helm upgrade --install hello-python helm/hello-python \
  --namespace hello-python
```
Verify:
```bash
kubectl get pods -n hello-python
kubectl get svc  -n hello-python
```

### 3. Ingress & ALB
- AWS Load Balancer Controller is installed via Helm
- Ingress provisions an **Application Load Balancer**
- External traffic is routed to the service

## CI/CD Pipeline (Jenkins)
### Jenkins Responsibilities
- Triggered by GitHub webhook (main branch)
- Build Docker image
- Push image to ECR
- Deploy to EKS using Helm
- Supports **DEV automatic deployment**
- **PROD deployment is gated and manual**

The Jenkins pipeline is defined in `Jenkinsfile.`

## GitOps Delivery (Argo CD)
### GitHub Actions
- Runs on the `gitops` branch
- Builds and pushes container images
- Updates Helm values with new image tags
## Argo CD
- Watches the **`gitops`** branch
- Syncs **Helm charts** to EKS
- Uses separate Argo CD Applications per environment:
  - **`hello-python`** (DEV)
  - **`hello-python-prod`** (PROD)

## Production Environment
- Separate Terraform state
- Separate EKS cluster
- Separate ALB and namespaces
- Same Helm chart for both environments, with separate values files (values.yaml for dev and values-prod.yaml for prod) that maintain configuration parity.
- Deployment requires manual approval
- Argo CD PROD sync is gated

## Observability & Monitoring
### Metrics
- Prometheus via `kube-prometheus-stack`
- Metrics Server for HPA
- ServiceMonitor for application metrics
### Dashboards
- Grafana dashboards for:
  - Request rate
  - Latency
  - Error rate
  - Cluster health
### Alerting
- Grafana alert rules
- Slack webhook notifications
- DEV configured; PROD would reuse with stricter thresholds

## Key Learnings
- Terraform modules enable scalable, reusable infrastructure
- Remote state and locking are critical for team workflows
- HPA alone is insufficient without Cluster Autoscaler
- GitOps simplifies and hardens Kubernetes deployments
- Monitoring must be designed alongside infrastructure
- Production gating prevents unsafe releases

## Cleanup
```bash
cd terraform/envs/dev
terraform destroy
```

(Repeat for prod if provisioned.)

## Notes
This project was intentionally designed to mirror real-world DevOps workflows, including:
- Multi-environment separation
- Git-based delivery
- Manual production gating
- Observability-first deployment
