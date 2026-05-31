# System Architecture Document

## Project Overview
**Repository:** SmitVgithub/3-tier-Application-via-Terraform
**Language:** HCL
**Request:** Build a real-time fleet management system called "TrackFleet" for a logistics company. It needs a web dashboard for dispatchers, an Android-only driver app with offline GPS tracking, and an iOS iPad app for warehouse managers. Integrate with Twilio for SMS alerts, Mapbox for live maps, and Stripe for invoice payments. Expected 500 drivers, 50 dispatchers, 10 warehouses. Budget under $300/month.

## Architecture Diagram

```mermaid
flowchart TD
    subgraph Clients["Client Applications"]
        WEB["Web Dashboard\n(Dispatchers - 50 users)"]
        ANDROID["Android Driver App\n(500 drivers)\nOffline GPS Tracking"]
        IPAD["iOS iPad App\n(Warehouse Managers - 10)"]
    end

    subgraph Backend["Backend Services"]
        API["TrackFleet API\n(Node.js/Express)"]
        WS["WebSocket Server\n(Real-time Updates)"]
        QUEUE["Message Queue\n(Redis)"]
        WORKER["Background Workers\n(GPS Processing)"]
    end

    subgraph Data["Data Layer"]
        DB[("PostgreSQL\n(Primary Database)")]
        CACHE[("Redis Cache\n(Session/GPS Buffer)")]
    end

    subgraph External["External Services"]
        TWILIO["Twilio\n(SMS Alerts)"]
        MAPBOX["Mapbox\n(Live Maps)"]
        STRIPE["Stripe\n(Invoice Payments)"]
    end

    WEB -->|"HTTPS"| API
    WEB <-->|"WSS"| WS
    ANDROID -->|"HTTPS + Sync"| API
    ANDROID <-->|"WSS"| WS
    IPAD -->|"HTTPS"| API
    IPAD <-->|"WSS"| WS

    API --> DB
    API --> CACHE
    API --> QUEUE
    WS --> CACHE
    QUEUE --> WORKER
    WORKER --> DB
    WORKER --> TWILIO

    API --> TWILIO
    API --> STRIPE
    WEB --> MAPBOX
    ANDROID --> MAPBOX
    IPAD --> MAPBOX
```

### Request Flow

```mermaid
sequenceDiagram
    autonumber
    participant Driver as Android Driver App
    participant API as TrackFleet API
    participant WS as WebSocket Server
    participant DB as PostgreSQL
    participant Redis as Redis Cache
    participant Dispatcher as Web Dashboard
    participant Twilio as Twilio SMS
    participant Mapbox as Mapbox

    Note over Driver,Mapbox: Flow 1: Driver GPS Tracking (Online)
    Driver->>+API: POST /api/location (GPS coords)
    API->>Redis: Buffer GPS data
    API->>WS: Broadcast location update
    WS->>Dispatcher: Real-time position update
    Dispatcher->>Mapbox: Render on live map
    API-->>-Driver: 200 OK

    Note over Driver,Mapbox: Flow 2: Offline GPS Sync
    Driver->>Driver: Store GPS locally (offline)
    Driver->>+API: POST /api/locations/batch (reconnect)
    API->>DB: Bulk insert GPS history
    API-->>-Driver: 200 Synced

    Note over Dispatcher,Twilio: Flow 3: Dispatcher Sends Alert
    Dispatcher->>+API: POST /api/alerts (driver_id, message)
    API->>DB: Log alert
    API->>+Twilio: Send SMS to driver
    Twilio-->>-API: SMS delivered
    API->>WS: Notify driver app
    WS->>Driver: Push notification
    API-->>-Dispatcher: Alert sent confirmation

    Note over Dispatcher,DB: Flow 4: Invoice Payment
    Dispatcher->>+API: POST /api/invoices/pay
    API->>Stripe: Create payment intent
    Stripe-->>API: Payment confirmed
    API->>DB: Update invoice status
    API-->>-Dispatcher: Payment success
```

### Database Schema

```mermaid
erDiagram
    USER ||--o{ VEHICLE : drives
    USER ||--o{ ALERT : receives
    USER ||--o{ INVOICE : manages
    USER {
        uuid id PK
        string email
        string password_hash
        string name
        string phone
        enum role "dispatcher|driver|warehouse_manager"
        uuid warehouse_id FK
        boolean is_active
        timestamp created_at
    }

    VEHICLE ||--o{ GPS_LOCATION : has
    VEHICLE ||--o{ TRIP : completes
    VEHICLE {
        uuid id PK
        string license_plate
        string make
        string model
        int year
        enum status "active|maintenance|inactive"
        uuid current_driver_id FK
        timestamp last_seen
    }

    GPS_LOCATION {
        uuid id PK
        uuid vehicle_id FK
        uuid driver_id FK
        decimal latitude
        decimal longitude
        float speed_kmh
        float heading
        boolean is_offline_sync
        timestamp recorded_at
        timestamp synced_at
    }

    TRIP ||--o{ GPS_LOCATION : tracks
    TRIP ||--|| WAREHOUSE : starts_from
    TRIP ||--o| WAREHOUSE : ends_at
    TRIP {
        uuid id PK
        uuid vehicle_id FK
        uuid driver_id FK
        uuid origin_warehouse_id FK
        uuid destination_warehouse_id FK
        enum status "planned|in_progress|completed|cancelled"
        timestamp scheduled_start
        timestamp actual_start
        timestamp actual_end
        float distance_km
    }

    WAREHOUSE ||--o{ USER : employs
    WAREHOUSE ||--o{ INVENTORY : stores
    WAREHOUSE {
        uuid id PK
        string name
        string address
        decimal latitude
        decimal longitude
        string contact_phone
        uuid manager_id FK
    }

    ALERT ||--|| USER : sent_by
    ALERT {
        uuid id PK
        uuid sender_id FK
        uuid recipient_id FK
        uuid vehicle_id FK
        string message
        enum type "sms|push|both"
        enum status "pending|sent|delivered|failed"
        string twilio_sid
        timestamp created_at
        timestamp delivered_at
    }

    INVOICE ||--o{ TRIP : covers
    INVOICE {
        uuid id PK
        string invoice_number
        uuid customer_id FK
        decimal amount
        enum status "draft|pending|paid|overdue"
        string stripe_payment_id
        date due_date
        timestamp paid_at
        timestamp created_at
    }

    INVENTORY {
        uuid id PK
        uuid warehouse_id FK
        string item_name
        string sku
        int quantity
        timestamp last_updated
    }
```

### Deployment Architecture

```mermaid
flowchart LR
    subgraph AppStores["App Distribution"]
        PLAYSTORE["Google Play Store\n(Android Driver App)"]
        APPSTORE["Apple App Store\n(iOS iPad App)"]
    end

    subgraph ClientDevices["Client Devices"]
        BROWSER["Web Browser\n(Dispatcher Dashboard)"]
        ANDROIDPHONE["Android Phones\n(500 Drivers)"]
        IPADS["iPads\n(10 Warehouse Managers)"]
    end

    subgraph CloudProvider["Cloud Infrastructure (Railway/Render - ~$50/mo)"]
        subgraph WebTier["Web Tier"]
            CDN["Cloudflare CDN\n(Static Assets - Free)"]
            LB["Load Balancer"]
        end

        subgraph AppTier["Application Tier"]
            API1["API Server 1\n(Node.js)"]
            API2["API Server 2\n(Node.js)"]
            WSSERVER["WebSocket Server\n(Socket.io)"]
            BGWORKER["Background Worker\n(GPS Processing)"]
        end

        subgraph DataTier["Data Tier (~$30/mo)"]
            POSTGRES[("PostgreSQL\n(Supabase Free/Neon)")]
            REDIS[("Redis\n(Upstash - Free tier)")]
        end
    end

    subgraph ExternalAPIs["External Services (~$100/mo)"]
        TWILIOAPI["Twilio\n(SMS - Pay per use)"]
        MAPBOXAPI["Mapbox\n(Free tier 50k loads)"]
        STRIPEAPI["Stripe\n(2.9% + 30¢ per txn)"]
    end

    PLAYSTORE -.->|"Install"| ANDROIDPHONE
    APPSTORE -.->|"Install"| IPADS

    BROWSER -->|"HTTPS"| CDN
    CDN --> LB
    ANDROIDPHONE -->|"HTTPS/WSS"| LB
    IPADS -->|"HTTPS/WSS"| LB

    LB --> API1
    LB --> API2
    LB --> WSSERVER

    API1 --> POSTGRES
    API2 --> POSTGRES
    API1 --> REDIS
    API2 --> REDIS
    WSSERVER --> REDIS
    BGWORKER --> POSTGRES
    BGWORKER --> REDIS

    API1 --> TWILIOAPI
    API2 --> TWILIOAPI
    BGWORKER --> TWILIOAPI
    API1 --> STRIPEAPI
    API2 --> STRIPEAPI

    BROWSER -.->|"Direct API"| MAPBOXAPI
    ANDROIDPHONE -.->|"Direct API"| MAPBOXAPI
    IPADS -.->|"Direct API"| MAPBOXAPI
```

## Architecture Narrative

Build a real-time fleet management system called "TrackFleet" for a logistics company. It needs a web dashboard for dispatchers, an Android-only driver app with offline GPS tracking, and an iOS iPad app for warehouse managers. Integrate with Twilio for SMS alerts, Mapbox for live maps, and Stripe for invoice payments. Expected 500 drivers, 50 dispatchers, 10 warehouses. Budget under $300/month.


---
*Generated by Blueprint Brain 1.7*
