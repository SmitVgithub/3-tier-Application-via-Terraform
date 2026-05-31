# Scalability Roadmap

## Stage: 0-1K MAU (Launch Phase: 500 drivers, 50 dispatchers, 10 warehouses)

**Users:** 0 - 1,000 MAU
**Estimated Cost:** $45/month

### Architecture Changes
- Deploy single Hetzner CX31 (4 vCPU, 8GB RAM) running Docker Compose with PostgreSQL, Redis, and Node.js API containers
- Implement GPS batch upload from Android driver app - collect points locally every 5 seconds, sync every 30 seconds when online to reduce API calls
- Configure PostgreSQL with TimescaleDB extension for efficient GPS time-series data storage with automatic 30-day retention compression
- Set up Nginx reverse proxy with SSL termination and WebSocket support for real-time dispatcher dashboard updates
- Implement Redis pub/sub for real-time fleet position broadcasting to dispatcher web dashboard (50 concurrent connections max)
- Configure Mapbox GL JS with client-side clustering to handle 500 vehicle markers efficiently on dispatcher dashboard

### New Components
- Hetzner Storage Box (100GB) for GPS data backups and driver document storage at €3.81/month
- Uptime Kuma self-hosted monitoring on same server for health checks and Twilio SMS alerting on downtime
- SQLite local database in Android driver app for offline GPS queue (up to 24 hours of tracking data)

### Key Metrics
- **apiResponseTime:** < 200ms p95 for dashboard queries
- **gpsIngestionRate:** 500 vehicles × 2 points/min = 1,000 GPS points/minute sustained
- **webSocketConnections:** 60 concurrent (50 dispatchers + 10 warehouse iPads)
- **availability:** 99.5% uptime target
- **databaseSize:** ~5GB/month GPS data before compression
- **twilioSmsVolume:** ~500 SMS/month for alerts at $0.0079/SMS = $4/month
- **mapboxMapLoads:** ~10,000 loads/month (free tier covers this)
- **stripeTransactions:** ~100 invoices/month at 2.9% + $0.30

## Stage: 1K-50K MAU (Regional Expansion: 5,000 drivers, 500 dispatchers, 100 warehouses)

**Users:** 1,000 - 50,000 MAU
**Estimated Cost:** $185/month

### Architecture Changes
- Migrate to Hetzner dedicated server AX41-NVMe (6-core Ryzen, 64GB RAM, 2×512GB NVMe) for 10x compute headroom
- Separate PostgreSQL/TimescaleDB to dedicated Hetzner CX41 with streaming replication to read replica for dashboard queries
- Implement Redis Cluster (3-node) on separate CX21 instances for high-availability pub/sub and session management
- Add HAProxy load balancer in front of 2 API server instances for zero-downtime deployments and failover
- Implement GPS data partitioning by fleet_id in TimescaleDB with automated chunk management for query performance
- Deploy dedicated WebSocket server (Socket.io cluster mode) handling 500+ concurrent dispatcher connections
- Add RabbitMQ for async processing of Twilio SMS queues, Stripe webhook handling, and GPS batch processing
- Implement read-through Redis caching for vehicle status, driver profiles, and route data with 5-minute TTL

### New Components
- Hetzner CX41 dedicated database server (8 vCPU, 16GB RAM) at €15.59/month
- Three Hetzner CX21 instances for Redis Cluster at €5.39/month each
- Grafana + Prometheus stack on CX21 for metrics, alerting, and GPS ingestion monitoring
- MinIO object storage on Hetzner for driver photos, delivery proof images, and document storage
- PgBouncer connection pooler to handle 500+ concurrent database connections efficiently

### Key Metrics
- **apiResponseTime:** < 150ms p95 for dashboard, < 50ms p95 for GPS ingestion
- **gpsIngestionRate:** 5,000 vehicles × 2 points/min = 10,000 GPS points/minute sustained
- **webSocketConnections:** 600 concurrent connections with <100ms broadcast latency
- **availability:** 99.9% uptime with automated failover
- **databaseSize:** ~50GB/month GPS data, 500GB total with 90-day retention
- **twilioSmsVolume:** ~5,000 SMS/month = $40/month
- **mapboxMapLoads:** ~100,000 loads/month = $50/month (beyond free tier)
- **stripeTransactions:** ~1,000 invoices/month
- **messageQueueThroughput:** 1,000 messages/minute through RabbitMQ

## Stage: 50K-500K MAU (National Scale: 50,000 drivers, 5,000 dispatchers, 1,000 warehouses)

**Users:** 50,000 - 500,000 MAU
**Estimated Cost:** $1450/month

### Architecture Changes
- Migrate to hybrid architecture: Hetzner dedicated servers for compute + managed TimescaleDB Cloud for database scaling
- Implement geographic sharding with regional API clusters (East/Central/West) using Hetzner's US and EU datacenters
- Deploy Kubernetes (k3s) cluster across 5 Hetzner dedicated servers for container orchestration and auto-scaling
- Implement CQRS pattern: separate write path (GPS ingestion) from read path (dashboard queries) with event sourcing
- Add Apache Kafka for GPS event streaming, enabling 100K+ points/minute ingestion with exactly-once semantics
- Implement CDN (Cloudflare) for static assets, Mapbox tile caching, and DDoS protection
- Deploy dedicated Twilio-integrated notification microservice with rate limiting and priority queuing
- Add Elasticsearch cluster for historical GPS data search, route analytics, and compliance reporting
- Implement API gateway (Kong) for rate limiting, authentication, and request routing across microservices

### New Components
- TimescaleDB Cloud Professional ($500/month) for managed time-series database with automatic scaling
- Three Hetzner AX101 dedicated servers (16-core, 128GB RAM) for Kubernetes worker nodes at €130/month each
- Confluent Cloud Basic for managed Kafka ($200/month) or self-hosted Kafka on dedicated hardware
- Elasticsearch cluster (3 nodes) on Hetzner CX51 instances for analytics and search
- Cloudflare Pro ($20/month) for CDN, WAF, and DDoS protection
- PagerDuty integration for 24/7 on-call alerting and incident management
- Dedicated load balancer pair (Hetzner Load Balancer) for high availability at €5.39/month each

### Key Metrics
- **apiResponseTime:** < 100ms p95 globally with regional routing
- **gpsIngestionRate:** 50,000 vehicles × 2 points/min = 100,000 GPS points/minute sustained
- **webSocketConnections:** 6,000 concurrent connections across regional clusters
- **availability:** 99.95% uptime with multi-region failover
- **databaseSize:** ~500GB/month GPS data, 5TB total with 1-year retention
- **twilioSmsVolume:** ~50,000 SMS/month = $400/month
- **mapboxMapLoads:** ~1,000,000 loads/month = $500/month
- **stripeTransactions:** ~10,000 invoices/month
- **kafkaThroughput:** 100,000 events/minute with <10ms latency
- **elasticsearchQueryTime:** < 500ms for 90-day historical queries

## Inflection Points

| Timing | Trigger | Action | Cost Delta |
|--------|---------|--------|------------|
| At 1,500-2,000 active drivers (Month 4-6) | GPS ingestion latency exceeds acceptable thresholds due to single PostgreSQL write bottleneck | Add TimescaleDB read replica and implement connection pooling with PgBouncer; batch GPS inserts in 100-point chunks | +$25/month for CX21 read replica + PgBouncer setup |
| At 300 dispatchers (Month 6-8) | WebSocket server memory exhaustion from concurrent dispatcher connections | Deploy dedicated Socket.io server with Redis adapter for horizontal scaling; separate WebSocket traffic from REST API | +$15/month for dedicated CX21 WebSocket server |
| At 2,000 active dashboard users (Month 8-10) | Mapbox API costs exceed budget allocation as map loads increase | Implement aggressive client-side tile caching, reduce map refresh rate from real-time to 10-second intervals, add Cloudflare caching for static tiles | +$20/month for Cloudflare Pro, saves $30-50/month on Mapbox = net savings |
| At enterprise customer acquisition (Month 10-12) | Single server becomes single point of failure; business requires higher availability SLA | Deploy HAProxy load balancer with 2 API server instances; implement automated health checks and failover; add database streaming replication | +$60/month for redundant infrastructure (2x API servers + load balancer) |
| At 3,000 drivers with geofence alerts enabled (Month 12-14) | Synchronous Twilio SMS sending causes API timeout during bulk alert scenarios | Implement RabbitMQ message queue for async SMS processing; add dedicated notification worker service with rate limiting | +$10/month for RabbitMQ on existing infrastructure |
| At 10,000 active drivers (Month 18-24) | GPS data volume exceeds single database server capacity; query performance degrades | Migrate to TimescaleDB Cloud or implement multi-node TimescaleDB cluster; add aggressive data retention policies with automatic downsampling | +$300-500/month for managed TimescaleDB Cloud vs +$150/month for self-managed cluster |
| At national expansion to 20,000+ drivers (Month 24-30) | Regional latency requirements for geographically distributed fleet operations | Deploy regional API clusters in Hetzner US (Ashburn) and EU (Falkenstein) datacenters; implement geographic routing via Cloudflare | +$400/month for secondary regional infrastructure |
| At 30,000+ drivers with multiple development teams (Month 30-36) | Monolithic architecture limits development velocity and deployment frequency | Decompose into microservices: GPS Ingestion, Fleet Management, Notifications, Billing; deploy on Kubernetes (k3s) with service mesh | +$500/month for Kubernetes infrastructure and operational overhead |
