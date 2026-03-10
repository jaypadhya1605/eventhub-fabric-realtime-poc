# Troubleshooting Guide

Common errors and fixes for the Event Hub → Fabric real-time analytics pipeline.

---

## Pre-Flight Issues

### Nothing works in Fabric (items missing, can't create Eventhouse/Eventstream)
**Cause:** Fabric capacity is paused or not assigned to the workspace.  
**Fix:**
1. Azure Portal → search for your Fabric capacity → check Status
2. If "Paused", click **Resume** (takes 1-3 minutes)
3. In Fabric portal, verify workspace settings → Workspace type shows "Fabric" with your capacity

### Azure CLI not recognizing Event Hub commands
**Cause:** The `Microsoft.EventHub` provider is not registered.  
**Fix:** Run:
```bash
az provider register --namespace Microsoft.EventHub
```
Wait 1-2 minutes, then retry.

---

## Event Hub Creation Issues

### "The specified name is not available"
**Cause:** Namespace names are globally unique (like storage accounts).  
**Fix:** Add a suffix: `evhns-molina-memberjourney-poc-01`

### "Location is not available for this subscription"
**Cause:** Region restricted or provider not registered.  
**Fix:** Try a different region or register the provider.

### Picked Basic tier instead of Standard
**Cause:** Basic tier doesn't support consumer groups beyond $Default, limits partitions to 4, has no Capture.  
**Fix:** You CANNOT upgrade Basic → Standard. Delete and recreate with Standard tier.

---

## Connection Issues

### "Connection failed" when connecting Eventstream to Event Hub
**Cause:** Wrong connection string, network restrictions, or missing permissions.  
**Fix:**
1. Verify connection string starts with `Endpoint=sb://`
2. Check the SAS policy has **Listen** permission
3. Confirm Event Hub namespace is not behind a Private Endpoint that blocks Fabric
4. Ensure namespace and Fabric capacity are in the same region

### Event Hub name not found
**Cause:** Event Hub names are case-sensitive.  
**Fix:** Use exact casing: `evh-callcenter-events` (not `evh-CallCenter-Events`)

### "Insufficient permissions"
**Cause:** Need Contributor on Azure resources + Admin/Member on Fabric workspace.  
**Fix:** Check both Azure RBAC and Fabric workspace access settings.

---

## Data Flow Issues

### Events sent but nothing in Eventhouse
**Cause:** Eventstream not activated.  
**Fix:** Go to Eventstream canvas → click **Activate** or **Publish**.

Also check:
- Destination (Eventhouse) is properly configured
- Wait 30-60 seconds for the first batch to appear

### KQL query returns "Table not found"
**Cause:** The streaming table is auto-created when first data arrives.  
**Fix:**
1. Send test events first
2. Check KQL database schema browser (left panel) for actual table name
3. Table name may differ from expected — use the name shown in the schema browser

### Schema not auto-detected in Eventstream
**Cause:** No events have arrived yet for Fabric to detect the schema.  
**Fix:** Send test events first, then configure the destination mapping.

---

## Python Script Issues

### ModuleNotFoundError: No module named 'azure.eventhub'
**Fix:** `pip install azure-eventhub`  
Or: `python -m pip install azure-eventhub`

### AuthenticationError / 401 Unauthorized
**Cause:** Wrong connection string or SAS policy missing "Send" permission.  
**Fix:** Verify connection string and SAS policy rights.

### EventHubError: messaging entity could not be found
**Cause:** Event Hub name doesn't match.  
**Fix:** Check spelling and case of the Event Hub name. Verify connection string points to correct namespace.

### MessageSizeExceededError
**Cause:** Event payload too large (max 1 MB per event).  
**Fix:** Reduce payload size. For test data, this should never happen.

---

## Dashboard Issues

### "Real-Time Dashboard" not in the New menu
**Cause:** RTI not enabled in Fabric workspace or capacity.  
**Fix:** Check workspace settings and capacity admin settings. Ensure capacity is running.

### KQL query returns empty results
**Cause:** No data sent, or time filter excludes test data.  
**Fix:** Run `CallCenterEvents | take 5` first (no time filter) to verify data exists.

### Dashboard does not auto-refresh
**Cause:** Auto-refresh is OFF by default.  
**Fix:** Dashboard settings → Auto-refresh interval → 30 seconds or 1 minute.

### "ago(1h)" returns nothing but data was just sent
**Cause:** EventTime timezone mismatch.  
**Fix:** Check what EventTime looks like: `CallCenterEvents | take 5 | project EventTime`  
The test script uses UTC. Ensure your KQL queries use UTC-based time comparisons.

---

## Cost Issues

### Capacity Metrics App shows no data
**Cause:** Takes up to 24 hours to populate.  
**Fix:** Install early, check the next day.

### Unexpected high CU consumption
**Cause:** Aggressive dashboard auto-refresh with complex KQL queries.  
**Fix:** Set refresh to 30-60 seconds for POC. Avoid refreshing every 10 seconds.

---

## Quick Diagnostic Checklist

If the pipeline isn't working, check these in order:

1. **Fabric capacity running?** → Azure Portal → Fabric capacity → Status = Active
2. **Event Hub namespace exists?** → Azure Portal → Resource group → Event Hub namespace
3. **SAS policy has correct rights?** → Send + Listen
4. **Eventstream activated?** → Fabric portal → Eventstream → Status = Active
5. **Destination configured?** → Eventstream → Destination → Eventhouse connected
6. **Events actually sent?** → Run the Python test script
7. **Table exists in KQL?** → Check schema browser in KQL database
8. **Dashboard connected?** → RTI dashboard → Tile → Correct KQL database selected
