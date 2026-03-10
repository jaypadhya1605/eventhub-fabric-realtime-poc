# Portal Walkthrough — Click-by-Click Instructions

This guide provides detailed portal instructions for users who prefer the Azure Portal and Fabric Portal over CLI commands.

---

## Part 1: Azure Portal (Event Hub Setup)

### 1.1 Create Resource Group

1. Go to [portal.azure.com](https://portal.azure.com)
2. Search **"Resource groups"** in the top search bar
3. Click **"+ Create"**
4. **Subscription:** Select your Azure subscription
5. **Resource group name:** `rg-molina-fabric-poc`
6. **Region:** Select the **same region as your Fabric capacity** (e.g., West US 3)
7. Click **"Review + create"** → **"Create"**

### 1.2 Create Event Hubs Namespace

1. Click **"+ Create a resource"**
2. Search **"Event Hubs"** → select **Event Hubs** (by Microsoft) → **"Create"**
3. Fill in the **Basics** tab:

| Setting | Value | Why |
|---------|-------|-----|
| Subscription | Your Azure subscription | Keep in your tenant |
| Resource Group | `rg-molina-fabric-poc` | POC isolation |
| Namespace Name | `evhns-molina-memberjourney-poc` | Globally unique name |
| Location | Same as Fabric capacity | Avoids latency + egress costs |
| Pricing Tier | **Standard** | Required for consumer groups, partitions > 4 |
| Throughput Units | **1** | Start small for POC |

4. Go to **"Advanced"** tab:
   - **Enable Auto-inflate:** Yes
   - **Maximum Throughput Units:** 5
5. Skip **"Networking"** (leave as public for POC)
6. Click **"Review + create"** → **"Create"**
7. Wait for deployment (30-60 seconds)
8. Click **"Go to resource"**

### 1.3 Create Event Hub (Topic)

1. From the namespace page, click **"Event Hubs"** in the left menu (under Entities)
2. Click **"+ Event Hub"**
3. Fill in:

| Setting | Value | Notes |
|---------|-------|-------|
| Name | `evh-callcenter-events` | One hub per event source |
| Partition Count | **4** | Cannot change after creation |
| Cleanup Policy | **Delete** | Messages expire after retention period |
| Retention time | **24 hours** | 1 day for POC |

4. Click **"Create"**

### 1.4 Create SAS Policy

1. From the namespace page, click **"Shared access policies"** (under Settings)
2. Click **"+ Add"**
3. **Policy name:** `molina-fabric-send-listen`
4. Check **both** boxes: **Send** and **Listen**
5. Click **"Create"**
6. Click on the policy name → copy **"Connection string – primary key"**
7. **Save this connection string** — you need it for Fabric and test scripts

---

## Part 2: Fabric Portal (Analytics Setup)

### 2.1 Create Eventhouse

1. Go to [app.fabric.microsoft.com](https://app.fabric.microsoft.com)
2. Navigate to your workspace
3. Click **"+ New"** → **"Eventhouse"**
4. Name: `eh-molina-memberjourney`
5. Click **"Create"**
6. A default KQL database is auto-created → rename to `kqldb-callcenter`

### 2.2 Create Eventstream

1. In your workspace, click **"+ New"** → **"Eventstream"**
2. Name: `es-molina-callcenter`
3. Click **"Create"**
4. The Eventstream canvas opens

### 2.3 Connect Event Hub to Eventstream

1. Click **"Add source"** → **"Azure Event Hubs"**
2. Fill in:

| Field | Value |
|-------|-------|
| Connection string | Paste from Step 1.4 |
| Event Hub name | `evh-callcenter-events` |
| Consumer group | `$Default` |
| Data format | `JSON` |

3. Click **"Connect"**

### 2.4 Connect Eventstream to Eventhouse

1. Click **"Add destination"** → **"Eventhouse"**
2. Select KQL database: `kqldb-callcenter`
3. Review auto-detected field mapping
4. Click **"Activate"** / **"Publish"**

### 2.5 Create Real-Time Dashboard

1. In your workspace, click **"+ New"** → **"Real-Time Dashboard"**
2. Name: `rtd-molina-callcenter`
3. Click **"Add tile"**
4. Connect to KQL database: `kqldb-callcenter`
5. Enter KQL queries from [dashboard-tiles.kql](../kql/dashboard-tiles.kql)
6. Set **auto-refresh:** Dashboard settings → 30 seconds

---

## Part 3: Verify the Pipeline

1. Run the test event script (see [send_test_events.py](../scripts/send_test_events.py))
2. Go to Eventhouse → KQL database → Query editor
3. Run: `CallCenterEvents | take 10`
4. You should see events within seconds
5. Check the Real-Time Dashboard — tiles should populate on next refresh
