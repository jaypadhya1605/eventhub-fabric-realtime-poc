# Azure Event Hubs → Microsoft Fabric Real-Time Analytics POC

**Industry:** Healthcare (Payer)  
**Use Case:** Real-time member journey analytics — call center events, campaign signals, application telemetry  
**Author:** Jay Padhya | Microsoft Health & Life Sciences

---

## What This POC Demonstrates

This proof-of-concept shows how to build a **real-time analytics pipeline** using Azure Event Hubs and Microsoft Fabric:

```
Operational Systems (Pega, Call Center, Campaign Platforms)
        ↓
Azure Event Hub (Ingestion Layer)
        ↓
Fabric Eventstream → Eventhouse (KQL Database)
        ↓
Real-Time Dashboards (RTI) + KQL Queries
        ↓
(Optional) Shortcuts to Lakehouse for historical joins
```

**Key Principle:** Event Hub is a transport/ingestion layer ONLY. It has no semantic model and no Power BI connection. All reporting happens downstream in Eventhouse or Real-Time Intelligence dashboards.

---

## Architecture

| Layer | Component | Purpose |
|-------|-----------|---------|
| **Ingestion** | Azure Event Hubs | High-throughput event ingestion (sub-second latency) |
| **Stream Processing** | Fabric Eventstream | Connects Event Hub to Fabric analytics |
| **Analytics Store** | Eventhouse (KQL Database) | Stores streaming data, enables KQL queries |
| **Visualization** | Real-Time Dashboard (RTI) | Live dashboards with auto-refresh |
| **Historical Join** | Lakehouse Shortcuts | Join streaming + batch data without duplication |

---

## Prerequisites

Before starting, confirm the following:

- [ ] **Azure subscription** with Contributor or Owner access on the target resource group
- [ ] **Microsoft Fabric capacity** (F2 or higher for POC; F64+ for production) — **must be running, not paused**
- [ ] **Fabric workspace** created with Eventhouse and Eventstream permissions
- [ ] **Azure CLI** installed ([install guide](https://learn.microsoft.com/cli/azure/install-azure-cli)) or access to [Azure Cloud Shell](https://shell.azure.com)
- [ ] **Python 3.8+** with pip (for sending test events)
- [ ] **Network access**: confirm if Private Endpoints are required or if public access is acceptable for POC

> **TIP:** For the POC, use public network access to reduce setup friction. Add Private Endpoints later for production hardening.

---

## Quick Start (< 15 minutes)

### Step 1 — Set Your Variables

Edit the values in `scripts/config.env` to match your environment:

```bash
# Copy and customize
cp scripts/config.env.template scripts/config.env
```

Or set them directly in your terminal:

```bash
export RESOURCE_GROUP="rg-molina-fabric-poc"
export LOCATION="westus3"
export NAMESPACE_NAME="evhns-molina-memberjourney-poc"
export EVENTHUB_NAME="evh-callcenter-events"
export SAS_POLICY_NAME="molina-fabric-send-listen"
```

### Step 2 — Deploy Event Hub Infrastructure

**Option A: One-command deploy script**

```bash
# Login to Azure (if not already)
az login

# Set your subscription
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# Run the deployment script
chmod +x scripts/deploy-eventhub.sh
./scripts/deploy-eventhub.sh
```

**Option B: Step-by-step Azure CLI**

```bash
# 1. Register the Event Hub provider (if needed)
az provider register --namespace Microsoft.EventHub

# 2. Create resource group (skip if it already exists)
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# 3. Create Event Hub namespace
az eventhubs namespace create \
  --resource-group $RESOURCE_GROUP \
  --name $NAMESPACE_NAME \
  --location $LOCATION \
  --sku Standard \
  --capacity 1 \
  --enable-auto-inflate true \
  --maximum-throughput-units 5

# 4. Create Event Hub (topic)
az eventhubs eventhub create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NAMESPACE_NAME \
  --name $EVENTHUB_NAME \
  --partition-count 4 \
  --cleanup-policy Delete \
  --retention-time 24

# 5. Create Shared Access Policy (Send + Listen)
az eventhubs namespace authorization-rule create \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NAMESPACE_NAME \
  --name $SAS_POLICY_NAME \
  --rights Send Listen

# 6. Get connection string (save this!)
az eventhubs namespace authorization-rule keys list \
  --resource-group $RESOURCE_GROUP \
  --namespace-name $NAMESPACE_NAME \
  --name $SAS_POLICY_NAME \
  --query primaryConnectionString \
  --output tsv
```

**Option C: Azure Portal (click-by-click)**

See the [Portal Walkthrough](docs/portal-walkthrough.md) for screenshot-level instructions.

### Step 3 — Configure Fabric (Portal Only)

These steps are done in the [Microsoft Fabric portal](https://app.fabric.microsoft.com):

1. **Create Eventhouse**
   - Workspace → `+ New` → `Eventhouse`
   - Name: `eh-molina-memberjourney`
   - A default KQL database is auto-created → rename to `kqldb-callcenter`

2. **Create Eventstream**
   - Workspace → `+ New` → `Eventstream`
   - Name: `es-molina-callcenter`
   - Add Source → `Azure Event Hubs`
   - Paste your connection string from Step 2
   - Event Hub name: `evh-callcenter-events`
   - Consumer group: `$Default`
   - Data format: `JSON`

3. **Connect Eventstream to Eventhouse**
   - Add Destination → `Eventhouse`
   - Select KQL database: `kqldb-callcenter`
   - Review auto-detected field mapping
   - Click `Activate` / `Publish`

> **IMPORTANT:** The Eventstream will show "Waiting for data" until you send events. This is normal.

### Step 4 — Send Test Events

```bash
# Install the SDK
pip install azure-eventhub

# Run the test script
python scripts/send_test_events.py
```

You will be prompted for your connection string, or set it as an environment variable:

```bash
export EVENT_HUB_CONNECTION_STRING="Endpoint=sb://your-namespace.servicebus.windows.net/;SharedAccessKeyName=...;SharedAccessKey=..."
```

### Step 5 — Verify Data in KQL

Open the KQL database in Fabric and run:

```kql
CallCenterEvents
| take 10
| project EventTime, CallType, MemberID, Duration, AgentID, Disposition
```

See [kql/queries.kql](kql/queries.kql) for more sample queries.

### Step 6 — Create Real-Time Dashboard

1. Workspace → `+ New` → `Real-Time Dashboard`
2. Name: `rtd-molina-callcenter`
3. Add tiles using the KQL queries in [kql/dashboard-tiles.kql](kql/dashboard-tiles.kql)
4. Enable auto-refresh: Dashboard settings → Auto-refresh → 30 seconds

---

## Repository Structure

```
eventhub-fabric-realtime-poc/
├── README.md                          # This file
├── scripts/
│   ├── deploy-eventhub.sh             # One-command deployment script
│   ├── deploy-eventhub.ps1            # PowerShell version for Windows
│   ├── config.env.template            # Environment variable template
│   ├── send_test_events.py            # Python script to send synthetic events
│   └── teardown.sh                    # Cleanup script to remove all resources
├── kql/
│   ├── queries.kql                    # Sample KQL queries for exploration
│   └── dashboard-tiles.kql            # KQL queries for RTI dashboard tiles
├── docs/
│   ├── portal-walkthrough.md          # Click-by-click portal instructions
│   ├── architecture-decisions.md      # Key architecture decision records
│   └── troubleshooting.md             # Common errors and fixes
├── .gitignore
└── LICENSE
```

---

## Event Hub vs Data Factory — When to Use Which

| Aspect | Event Hub | Data Factory |
|--------|-----------|-------------|
| **Pattern** | Streaming | Batch / near-real-time |
| **Latency** | Seconds | Minutes / hours |
| **Use Case** | Live signals (calls, campaigns, telemetry) | Historical ingestion (claims, enrollment, bulk loads) |
| **Feeds Eventhouse?** | Yes — via Eventstream | No — feeds Lakehouse |
| **Feeds Lakehouse?** | Not directly (use Eventhouse shortcuts) | Yes — primary batch target |

**Rule of Thumb:** If the data is event-driven and time-sensitive → Event Hub. If it's historical or batch → Data Factory. Both converge in Eventhouse via shortcuts.

---

## Latency Expectations

| Stage | Expected Latency | Notes |
|-------|-----------------|-------|
| Event Hub ingestion | Sub-second to seconds | From producer to Event Hub partition |
| Eventstream processing | Seconds | Picks up events nearly instantly |
| Eventhouse → Dashboard | Sub-minute | RTI dashboards auto-refresh on configurable interval |
| Eventhouse → OneLake | Minutes | Use RTI dashboards for live views, not OneLake |

> **NOTE:** Use Real-Time Intelligence (RTI) dashboards — NOT Power BI streaming datasets. RTI is the strategic direction in Fabric.

---

## Cost Estimates (POC)

| Component | Cost Driver | POC Estimate |
|-----------|------------|-------------|
| Event Hub (Standard, 1 TU) | ~$0.030/hr per TU + ingress events | ~$25/month |
| Fabric Capacity (F2 minimum) | CU consumption | ~$263/month (pause when not in use) |
| **Total POC** | | **~$288/month** (pause capacity to minimize) |

> **IMPORTANT:** Do NOT estimate production cost from Day 1 POC numbers. You need 3–5 days of representative load to project accurately. Enable the [Fabric Capacity Metrics App](https://appsource.microsoft.com) to monitor CU consumption.

---

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for the complete guide. Quick reference:

| Symptom | Most Likely Fix |
|---------|----------------|
| Nothing works in Fabric | Fabric capacity is paused → Resume it in Azure Portal |
| Event Hub namespace creation fails | Provider not registered → `az provider register --namespace Microsoft.EventHub` |
| Cannot connect Eventstream to Event Hub | Connection string wrong, or behind private endpoint |
| Events sent but nothing in Eventhouse | Eventstream not activated → Activate/Publish it |
| KQL query fails | Table name mismatch → Check KQL database schema browser |
| Dashboard shows no data | Auto-refresh is off → Enable in dashboard settings |

---

## Production Hardening Checklist

When moving from POC to production, address these items:

- [ ] Migrate from SAS policies to **Managed Identity** authentication
- [ ] Increase partition count (8–16 for production call center workloads)
- [ ] Enable **Capture** to auto-archive events to ADLS/OneLake
- [ ] Add **Private Endpoints** for network isolation
- [ ] Create **dedicated consumer groups** (one per consumer)
- [ ] Set up **Azure Monitor alerts** for throttling and errors
- [ ] Configure **message retention** to 7 days (Standard tier max)
- [ ] Scale Fabric capacity to match production query load

---

## Cleanup

To remove all POC resources and stop billing:

```bash
# Remove Event Hub resources
chmod +x scripts/teardown.sh
./scripts/teardown.sh

# IMPORTANT: Pause Fabric capacity in Azure Portal
# Azure Portal → Fabric capacity → Pause
```

---

## References

- [Azure Event Hubs Documentation](https://learn.microsoft.com/azure/event-hubs/)
- [Microsoft Fabric Eventstream](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/overview)
- [Eventhouse & KQL Database](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse)
- [Real-Time Dashboards in Fabric](https://learn.microsoft.com/fabric/real-time-intelligence/dashboard-real-time-create)
- [Fabric Capacity Metrics App](https://learn.microsoft.com/fabric/enterprise/metrics-app)

---

## License

This project is provided as a POC accelerator. See [LICENSE](LICENSE) for details.

## Contributing

For questions or feedback, contact [Jay Padhya](https://github.com/jaypadhya1605) | Microsoft Health & Life Sciences.
