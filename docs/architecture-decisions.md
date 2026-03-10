# Architecture Decision Records

Key decisions made for this POC and considerations for production.

---

## ADR-1: Event Hub vs Kafka

**Decision:** Use Azure Event Hubs for the POC.

**Context:** Molina has existing Confluent Kafka clusters. Both Event Hub and Kafka can feed Fabric Eventstream.

**Rationale:**
- Event Hub is simpler to operationalize inside Azure
- Native integration with Fabric Eventstream (no connectors needed)
- Kafka can be added later — this is not an either-or decision
- Fabric Eventstream supports both as sources

**Production Note:** If Molina prefers Kafka, switch the Eventstream source from Event Hub to Kafka. The rest of the pipeline (Eventhouse, dashboards) stays the same.

---

## ADR-2: Streaming (Event Hub) vs Batch (Data Factory)

**Decision:** Use Event Hub for real-time signals. Use Data Factory for historical/batch data.

| Aspect | Event Hub | Data Factory |
|--------|-----------|-------------|
| Pattern | Streaming | Batch |
| Latency | Seconds | Minutes/hours |
| Feeds | Eventhouse (via Eventstream) | Lakehouse |
| Use Case | Call center events, campaigns | Claims history, enrollment files |

**Key Insight:** Both paths converge in Eventhouse via shortcuts — streaming + historical data joined in KQL.

---

## ADR-3: SAS Policy vs Managed Identity

**Decision:** Use SAS policy for POC, migrate to Managed Identity for production.

**Rationale:**
- SAS policy is faster to set up (minutes vs hours)
- No dependency on Fabric workspace managed identity configuration
- Connection string can be pasted directly into Eventstream

**Production Migration:**
- Assign Fabric workspace Managed Identity → Azure Event Hubs Data Receiver role
- Assign producer app Managed Identity → Azure Event Hubs Data Sender role
- No connection strings to rotate or leak

---

## ADR-4: RTI Dashboards vs Power BI Streaming Datasets

**Decision:** Use Real-Time Intelligence (RTI) dashboards, not Power BI streaming datasets.

**Rationale:**
- RTI dashboards are the strategic direction in Fabric
- Direct connection to Eventhouse KQL database
- Built-in auto-refresh support
- Power BI streaming datasets are being deprecated

---

## ADR-5: Partition Count

**Decision:** 4 partitions for POC, 8-16 for production.

**Rationale:**
- Each partition handles ~1 MB/s ingress, ~2 MB/s egress
- 4 is sufficient for low-volume POC testing
- **Partition count CANNOT be changed after creation** — plan for production peak

**Production Sizing:**
- Call center with 500 concurrent agents: 8 partitions
- Call center with 2000+ concurrent agents: 16 partitions
- Always account for traffic spikes (holiday periods, open enrollment)

---

## ADR-6: Cost Monitoring Approach

**Decision:** Observe-then-estimate. No production cost commitments on Day 1.

**Process:**
1. Deploy POC with 1 TU, auto-inflate to 5
2. Enable Fabric Capacity Metrics App
3. Run representative load for 3-5 days
4. Analyze actual CU consumption
5. Then project production costs

**Expected POC cost:** ~$25/month (Event Hub) + Fabric capacity cost (depends on SKU and usage).
