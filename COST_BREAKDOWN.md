# Cost Breakdown

> Prices as of 2026-05-31. ±15-25% variance expected.

## Recommended Cloud: **HETZNER**
At $22/month vs $109-169/month for hyperscalers, Hetzner delivers 5-7x cost savings while meeting all technical requirements for 500 drivers, well under the $300 budget.

## Monthly Cost Summary

| Cloud | Monthly (USD) |
|-------|---------------|
| AWS | $132.85 |
| GCP | $109.26 |
| AZURE | $169.46 |
| HETZNER | $22.42 |

## Line Items by Cloud

### AWS

| Component | Service | Unit Cost | Quantity | Monthly USD |
|-----------|---------|-----------|----------|-------------|
| api-server | EC2 t3.small (API Server) | $0.0208/hour | 730.00 | $15.18 |
| websocket-server | EC2 t3.micro (WebSocket Server) | $0.0104/hour | 730.00 | $7.59 |
| database | RDS PostgreSQL db.t3.micro | $0.018/hour | 730.00 | $13.14 |
| redis-cache | ElastiCache Redis t3.micro | $0.017/hour | 730.00 | $12.41 |
| storage | S3 Storage (GPS logs, assets) | $0.023/GB-month | 100.00 | $2.30 |
| load-balancer | ALB (Load Balancer) | $0.0225/hour | 730.00 | $16.43 |
| egress | Data Transfer Out | $0.09/GB | 150.00 | $4.50 |
| queue | SQS (GPS queue processing) | $0.4/million-requests | 5.00 | $2.00 |

#### ⚠️ Hidden Costs

| Category | Description | Est. Monthly USD |
|----------|-------------|------------------|
| networking | NAT Gateway for private subnets | $32.4 |
| networking | Cross-AZ data transfer | $5 |
| storage | RDS automated snapshots (20GB) | $1.9 |
| monitoring | CloudWatch logs & metrics | $8 |
| networking | ALB LCU charges (real-time GPS) | $12 |

### GCP

| Component | Service | Unit Cost | Quantity | Monthly USD |
|-----------|---------|-----------|----------|-------------|
| api-server | e2-small (API Server) | $0.0168/hour | 730.00 | $12.26 |
| websocket-server | e2-micro (WebSocket Server) | $0.0084/hour | 730.00 | $6.13 |
| database | Cloud SQL PostgreSQL db-f1-micro | $0.015/hour | 730.00 | $10.95 |
| redis-cache | Memorystore Redis 1GB | $0.016/hour | 730.00 | $11.68 |
| storage | Cloud Storage Standard | $0.02/GB-month | 100.00 | $2.00 |
| load-balancer | Cloud Load Balancing | $0.008/hour | 730.00 | $5.84 |
| egress | Network Egress | $0.08/GB | 150.00 | $12.00 |
| queue | Cloud Pub/Sub | $0.4/million-requests | 5.00 | $0.00 |

#### ⚠️ Hidden Costs

| Category | Description | Est. Monthly USD |
|----------|-------------|------------------|
| networking | Cloud NAT for private instances | $32 |
| networking | LB forwarding rules (additional) | $8 |
| storage | Cloud SQL storage & backups | $3.4 |
| monitoring | Cloud Logging ingestion | $5 |

### AZURE

| Component | Service | Unit Cost | Quantity | Monthly USD |
|-----------|---------|-----------|----------|-------------|
| api-server | Standard_B2s (API Server) | $0.0416/hour | 730.00 | $30.37 |
| websocket-server | Standard_B1ms (WebSocket Server) | $0.0207/hour | 730.00 | $15.11 |
| database | Azure Database PostgreSQL Basic | $0.034/hour | 730.00 | $24.82 |
| redis-cache | Azure Cache Redis C0 | $0.022/hour | 730.00 | $16.06 |
| storage | Blob Storage LRS | $0.018/GB-month | 100.00 | $1.80 |
| load-balancer | Load Balancer Standard | $0.025/hour | 730.00 | $18.25 |
| egress | Bandwidth Out | $0.087/GB | 150.00 | $13.05 |
| queue | Service Bus Standard | $0.05/million-requests | 5.00 | $0.00 |

#### ⚠️ Hidden Costs

| Category | Description | Est. Monthly USD |
|----------|-------------|------------------|
| networking | NAT Gateway | $32 |
| networking | LB data processing charges | $8 |
| storage | Managed disk snapshots | $4 |
| monitoring | Azure Monitor logs | $6 |

### HETZNER

| Component | Service | Unit Cost | Quantity | Monthly USD |
|-----------|---------|-----------|----------|-------------|
| api-server | CX21 (API + WebSocket combined) | $5.39/month | 1.00 | $5.39 |
| worker-server | CX11 (Background workers) | $3.29/month | 1.00 | $3.29 |
| database-server | CX21 (PostgreSQL + Redis self-hosted) | $5.39/month | 1.00 | $5.39 |
| storage | Object Storage | $0.0057/GB-month | 100.00 | $0.57 |
| load-balancer | Load Balancer LB11 | $5.39/month | 1.00 | $5.39 |
| egress | Data Transfer (20TB included) | $0/GB | 150.00 | $0.00 |
| backup | Managed Backup 20GB | $2.39/month | 1.00 | $2.39 |

#### ⚠️ Hidden Costs

| Category | Description | Est. Monthly USD |
|----------|-------------|------------------|
| devops | Self-managed DB/Redis setup & maintenance (~4hrs/mo) | $0 |
| networking | Private networking (free) | $0 |
| monitoring | External monitoring (UptimeRobot free tier) | $0 |
| ssl | Let's Encrypt (free) | $0 |

