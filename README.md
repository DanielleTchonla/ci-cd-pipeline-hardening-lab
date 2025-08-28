# ci-cd-pipeline-hardening-lab

# CI/CD Pipeline Hardening Lab

## Project Goal

Build a reliable, fast, and observable CI/CD pipeline for a containerized app deployed on AWS EKS. This lab addresses flaky failures, long build times, and provides infrastructure as code.

---

## Prerequisites

* AWS account with admin access
* AWS CLI configured (`aws configure`)
* `eksctl` installed
* `kubectl` installed
* Terraform >= 1.5
* Docker installed
* GitHub account
* Optional: Slack webhook for notifications

---

## Project Structure

```text
ci-cd-pipeline-hardening-lab/
├── app/                     # Simple app (Python Flask or Node.js)
├── Dockerfile
├── ci-cd/
│   ├── jenkins/             # Jenkins pipeline (optional)
│   ├── github-actions/      # GitHub Actions workflow
├── eks/
│   ├── eksctl-cluster.yaml
├── terraform/
│   ├── vpc.tf
│   ├── eks.tf
│   ├── outputs.tf
├── .github/workflows/
│   └── main.yml             # GitHub Actions workflow
├── k8s/
│   └── deployment.yaml      # Kubernetes deployment manifest
├── README.md
```

---

## Architecture & CI/CD Workflow

```text
   +-----------+        +-------------+        +------------+
   | Developer | ---->  | GitHub Repo | ---->  | GitHub     |
   | Push Code |        | (App + CI) |        | Actions /  |
   +-----------+        +-------------+        | Jenkins    |
                                               +------------+
                                                      |
                                                      v
                                               +-------------+
                                               | Docker Build |
                                               | & Push to ECR|
                                               +-------------+
                                                      |
                                                      v
                                               +-------------+
                                               | AWS EKS     |
                                               | (Managed NG)|
                                               +-------------+
                                                      |
                                                      v
                                               +-------------+
                                               | App Running |
                                               | in Cluster  |
                                               +-------------+
```

* **Developer pushes code → GitHub Actions triggers build → Docker image pushed to ECR → EKS deploys container → App running on cluster**

---

## Phase 1: Minimal App + Docker

### 1. Example Flask App

Create a file `app/app.py`:

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, CI/CD Pipeline!"

@app.route("/health")
def health():
    return "OK"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

### 2. Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY app/ /app
RUN pip install flask
CMD ["python", "app.py"]
```

Build and test locally:

```bash
docker build -t flask-cicd .
docker run -p 5000:5000 flask-cicd
curl http://localhost:5000/health
```

---

## Phase 2: AWS Infra Setup

### 1. Terraform: VPC, IAM, EKS

```bash
cd terraform/
terraform init
terraform plan
terraform apply -auto-approve
```

* Creates VPC, subnets, IAM roles for EKS nodes, and outputs.

### 2. Create EKS cluster with `eksctl`

```bash
eksctl create cluster -f eks/eksctl-cluster.yaml
```

### 3. Associate IAM OIDC Provider

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster cicd-cluster \
  --approve
```

### 4. Confirm Nodes are Ready

```bash
kubectl get nodes
```

---

## Phase 3: CI/CD Pipeline Setup (GitHub Actions)

1. Create `.github/workflows/main.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Docker
        uses: docker/setup-buildx-action@v2
      - name: Build & Push Docker Image
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ secrets.ECR_REPO_URL }}:latest
      - name: Deploy to EKS
        run: |
          aws eks update-kubeconfig --region us-east-1 --name cicd-cluster
          kubectl apply -f k8s/deployment.yaml
```

2. Store your ECR repo URL as a **GitHub secret**: `ECR_REPO_URL`.

---

## Phase 4: Deploy to EKS

Example `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app
        image: #your image name in ecr
        ports:
        - containerPort: 5000
```

Apply the deployment:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl get pods -w
kubectl get svc
```

---

## Phase 5: Pipeline Hardening

* Add **stage-level retries** in GitHub Actions.
* Enable **Slack/webhook notifications** for failures.
* Enable **Docker layer caching** to reduce build times.
* Simulate failures to test pipeline resilience.

---

## Troubleshooting

| Issue                                                     | Solution                                                                      |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `pods are unevictable` during node deletion               | Drain manually: `kubectl drain <node-name> --ignore-daemonsets --force`       |
| `connection timed out` to EKS API                         | Verify your network, security groups, and kubeconfig                          |
| Terraform errors referencing undeclared `aws_eks_cluster` | Make sure your cluster module is correctly referenced in nodegroup.tf         |
| GitHub Actions fails pushing Docker image                 | Ensure `ECR_REPO_URL` secret is correct and GitHub Action has AWS credentials |

---

## Done

After following these steps, you should have:

* EKS cluster running with managed node groups
* Flask app deployed in Kubernetes
* CI/CD pipeline fully automated via GitHub Actions
* Pipeline hardened against flaky builds and failures

---

## References

* [EKS Documentation](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
* [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
* [GitHub Actions Docs](https://docs.github.com/en/actions)
