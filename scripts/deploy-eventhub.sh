#!/bin/bash
# =============================================================================
# Azure Event Hubs Deployment Script
# Molina Healthcare — Member Journey Real-Time Analytics POC
# =============================================================================

set -e

# Load config if available
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

# Default values (override via config.env or environment variables)
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-molina-fabric-poc}"
LOCATION="${LOCATION:-westus3}"
NAMESPACE_NAME="${NAMESPACE_NAME:-evhns-molina-memberjourney-poc}"
EVENTHUB_NAME="${EVENTHUB_NAME:-evh-callcenter-events}"
SAS_POLICY_NAME="${SAS_POLICY_NAME:-molina-fabric-send-listen}"
PARTITION_COUNT="${PARTITION_COUNT:-4}"
MAX_THROUGHPUT_UNITS="${MAX_THROUGHPUT_UNITS:-5}"
RETENTION_HOURS="${RETENTION_HOURS:-24}"

echo "============================================"
echo "  Event Hubs Deployment for Fabric POC"
echo "============================================"
echo ""
echo "Configuration:"
echo "  Resource Group:     $RESOURCE_GROUP"
echo "  Location:           $LOCATION"
echo "  Namespace:          $NAMESPACE_NAME"
echo "  Event Hub:          $EVENTHUB_NAME"
echo "  Partitions:         $PARTITION_COUNT"
echo "  Max TU:             $MAX_THROUGHPUT_UNITS"
echo ""

# ---- Step 1: Register provider ----
echo "[1/6] Registering Microsoft.EventHub provider..."
az provider register --namespace Microsoft.EventHub --wait 2>/dev/null || true
echo "  ✓ Provider registered"

# ---- Step 2: Create resource group ----
echo "[2/6] Creating resource group '$RESOURCE_GROUP'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "  ✓ Resource group ready"

# ---- Step 3: Create namespace ----
echo "[3/6] Creating Event Hubs namespace '$NAMESPACE_NAME'..."
az eventhubs namespace create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NAMESPACE_NAME" \
  --location "$LOCATION" \
  --sku Standard \
  --capacity 1 \
  --enable-auto-inflate true \
  --maximum-throughput-units "$MAX_THROUGHPUT_UNITS" \
  --output none
echo "  ✓ Namespace created (Standard tier, auto-inflate to $MAX_THROUGHPUT_UNITS TU)"

# ---- Step 4: Create Event Hub ----
echo "[4/6] Creating Event Hub '$EVENTHUB_NAME'..."
az eventhubs eventhub create \
  --resource-group "$RESOURCE_GROUP" \
  --namespace-name "$NAMESPACE_NAME" \
  --name "$EVENTHUB_NAME" \
  --partition-count "$PARTITION_COUNT" \
  --cleanup-policy Delete \
  --retention-time "$RETENTION_HOURS" \
  --output none
echo "  ✓ Event Hub created ($PARTITION_COUNT partitions, ${RETENTION_HOURS}h retention)"

# ---- Step 5: Create SAS policy ----
echo "[5/6] Creating SAS policy '$SAS_POLICY_NAME'..."
az eventhubs namespace authorization-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --namespace-name "$NAMESPACE_NAME" \
  --name "$SAS_POLICY_NAME" \
  --rights Send Listen \
  --output none
echo "  ✓ SAS policy created (Send + Listen)"

# ---- Step 6: Get connection string ----
echo "[6/6] Retrieving connection string..."
CONNECTION_STRING=$(az eventhubs namespace authorization-rule keys list \
  --resource-group "$RESOURCE_GROUP" \
  --namespace-name "$NAMESPACE_NAME" \
  --name "$SAS_POLICY_NAME" \
  --query primaryConnectionString \
  --output tsv)

echo ""
echo "============================================"
echo "  DEPLOYMENT COMPLETE"
echo "============================================"
echo ""
echo "Connection String (save this — you need it for Fabric Eventstream and test scripts):"
echo ""
echo "  $CONNECTION_STRING"
echo ""
echo "Next steps:"
echo "  1. Go to https://app.fabric.microsoft.com"
echo "  2. Create Eventhouse → Eventstream → Connect Event Hub"
echo "  3. Run: python scripts/send_test_events.py"
echo "  4. Verify data in KQL database"
echo "  5. Create Real-Time Dashboard"
echo ""
echo "See README.md for detailed instructions."
