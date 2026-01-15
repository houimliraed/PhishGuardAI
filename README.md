# PhishGuardAI

[![Pipeline Status](https://gitlab.com/houimliraed/ml-devops/badges/main/pipeline.svg)](https://gitlab.com/houimliraed/ml-devops/-/pipelines)
[![Coverage](https://gitlab.com/houimliraed/ml-devops/badges/main/coverage.svg)](https://gitlab.com/houimliraed/ml-devops/-/graphs/main/charts)

ML-powered phishing URL detection system built with FastAPI, React, and deployed on AWS EKS.

## Overview

PhishGuardAI detects phishing URLs using a RandomForest classifier trained on URL feature patterns. The application runs on Kubernetes (AWS EKS) with a React frontend, FastAPI backend, and Redis caching layer.

**Stack:**
- Frontend: React 18 + Vite + Nginx
- Backend: FastAPI + Python 3.12 + scikit-learn
- Infrastructure: AWS EKS, S3, ElastiCache, ECR
- CI/CD: GitLab pipelines with automated security scanning

---

## Infrastructure

### AWS Services

**Compute:**
- EKS cluster running containerized workloads
- EC2 worker nodes with auto-scaling groups
- Application Load Balancer for traffic distribution

**Storage:**
- S3 for ML model artifacts and static assets
- ElastiCache (Redis) for prediction caching

**Security & Networking:**
- VPC with isolated subnets
- IAM roles with IRSA for pod-level permissions
- CloudWatch for logging and monitoring
- WAF for application-level protection

**Container Registry:**
- ECR for Docker images

### Architecture

```
Internet → ALB → EKS Cluster
                   ├── Frontend Pods (Nginx)
                   ├── Backend Pods (FastAPI)
                   └── ML Inference Engine
                         ├── S3 (models)
                         └── ElastiCache (cache)
```

Detailed architecture:

```
┌─────────────────────────────────────────────────────────┐
│                      AWS VPC                             │
│                                                          │
│  Internet Gateway                                        │
│         │                                                │
│         ▼                                                │
│  [ Application Load Balancer ]                          │
│         │                                                │
│         ▼                                                │
│  ┌──────────────────────────────────────────┐           │
│  │         EKS Cluster                      │           │
│  │                                          │           │
│  │  ┌────────────┐    ┌────────────┐      │           │
│  │  │  Frontend  │    │  Backend   │      │           │
│  │  │  (React)   │    │  (FastAPI) │      │           │
│  │  │  replicas:3│    │  replicas:5│      │           │
│  │  └────────────┘    └──────┬─────┘      │           │
│  │                           │             │           │
│  │                    ┌──────▼──────┐     │           │
│  │                    │ ML Inference│     │           │
│  │                    │   Engine    │     │           │
│  │                    └──────┬──────┘     │           │
│  └───────────────────────────┼────────────┘           │
│                              │                         │
│         ┌────────────────────┼──────────┐              │
│         ▼                    ▼          ▼              │
│     [ S3 ]            [ElastiCache]  [Secrets]         │
│    (models)              (Redis)      Manager          │
│                                                         │
│  [ CloudWatch Logs & Metrics ]                         │
└─────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Frontend
- React 18 (hooks, functional components)
- Vite (build tool)
- Nginx (production server)
- TypeScript

### Backend
- FastAPI (async REST API)
- Python 3.12
- Uvicorn (ASGI server)
- Pydantic (validation)

### ML Pipeline
- scikit-learn (RandomForest)
- pandas (feature engineering)
- NumPy
- Jupyter (training notebooks)

### Infrastructure
- Kubernetes (EKS)
- Docker + Docker Compose
- Helm (package management)
- kubectl

### DevOps
- GitLab CI/CD
- ECR (container registry)
- Trivy (security scanning)

---

## Setup

### Local Development

1. Generate ML models:
   ```bash
   cd notebooks/
   jupyter notebook phishing_detection_training.ipynb
   # Run all cells to generate models in /backend/app/models/
   ```

2. Start services:
   ```bash
   docker compose up --build
   ```

   Backend: http://localhost:4000  
   Frontend: http://localhost:8080

### Project Structure

```
PhishGuardAI/
├── backend/
│   ├── app/
│   │   ├── api/         # REST endpoints
│   │   ├── core/        # ML logic
│   │   ├── models/      # Generated models
│   │   └── schemas/     # Request/response schemas
│   └── requirements.txt
├── frontend/
│   ├── src/
│   ├── package.json
│   └── vite.config.js
├── notebooks/
│   └── phishing_detection_training.ipynb
└── docker-compose.yml
```

---

## CI/CD Pipeline

GitLab pipeline with three stages:

**Build:**
- Build Docker images
- Push to ECR with commit SHA tags

**Test:**
- Unit tests (pytest, vitest)
- Security scans (SAST, secret detection, dependency check)
- Integration tests with docker-compose

**Deploy:**
- Staging: auto-deploy from `develop` branch
- Production: manual deploy from `main` branch
- Rolling updates via `kubectl apply`

```yaml
# Example pipeline config
include:
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
```

---

## Security

### Automated Scanning
- SAST: Source code vulnerability detection
- Secret detection: Prevent credential leaks
- Dependency scanning: CVE checks for third-party libraries
- Container scanning: Docker image analysis

### Container Security
- mTLS for Docker daemon communication
- Credential masking in CI logs
- Non-root containers

### AWS Security
- IAM roles with least privilege
- VPC isolation (private subnets for backend)
- Secrets Manager for credentials
- WAF rules (SQL injection, XSS protection)
- CloudWatch alarms for anomaly detection

### Deployment Controls
- Manual approval gates for production
- Immutable image tags (commit SHA)
- Automated rollback capability

### Data Management
- Build artifacts expire after 7 days
- S3 lifecycle policies for log archival
- Automated backups with 30-day retention

---

## Deployment

**Environments:**
- Development: Local Docker Compose
- Staging: AWS EKS (auto-deploy from `develop`)
- Production: AWS EKS (manual deploy from `main`)

**URLs:**
- Staging: https://staging.phishguard.example.com
- Production: https://phishguard.example.com

---

## Configuration

### Environment Variables

```env
# Backend
APP_MODULE=app.main:app
PORT=4000
REDIS_URL=redis://elasticache-endpoint:6379
AWS_S3_BUCKET=phishguard-models
AWS_REGION=us-east-1

# Frontend
VITE_API_BASE=/api
VITE_AWS_CLOUDFRONT_URL=https://cdn.phishguard.example.com

# Kubernetes
K8S_NAMESPACE=phishguard-prod
EKS_CLUSTER_NAME=phishguard-cluster
```

For EKS deployments, use Kubernetes Secrets + AWS Secrets Manager with IRSA.

---

## Testing

### Backend
```bash
cd backend
pip install -r requirements.txt
pip install pytest pytest-cov pytest-asyncio httpx
pytest tests/ --cov=app --cov-report=html
```

### Frontend
```bash
cd frontend
npm install
npm test
```

### Integration
```bash
docker compose up -d
pytest tests/integration/
docker compose down
```

---

## Features

- Real-time URL feature extraction (20+ features)
- RandomForest classifier (95%+ accuracy)
- REST API with automatic documentation (FastAPI)
- React dashboard with live predictions
- Auto-scaling on Kubernetes
- Redis caching for low latency
- S3-based model versioning
- CloudWatch monitoring and alerting

---

## Documentation

- [Architecture Documentation](ARCHITECTURE.md)
- [Deployment Guide](DEPLOYMENT.md)
- [User Stories](USER_STORIES.md)
- [API Documentation](http://localhost:4000/docs)

---

## Notes

**ML Models:**  
Model files in `backend/app/models/` are generated locally and not tracked in git. Run the Jupyter notebook to regenerate them.

**Security:**  
Never commit secrets. Use GitLab CI variables or AWS Secrets Manager.

**AWS Costs:**  
Monitor usage with AWS Cost Explorer to avoid unexpected charges.

---

## License

MIT
