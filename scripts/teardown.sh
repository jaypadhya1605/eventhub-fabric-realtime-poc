#!/bin/bash
# =============================================================================
# Teardown Script — Remove all POC resources
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/config.env" ]; then
    source "$SCRIPT_DIR/config.env"
fi

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-molina-fabric-poc}"
NAMESPACE_NAME="${NAMESPACE_NAME:-evhns-molina-memberjourney-poc}"

echo "============================================"
echo "  TEARDOWN — Remove POC Resources"
echo "============================================"
echo ""
echo "This will delete:"
echo "  - Event Hub namespace: $NAMESPACE_NAME"
echo "  - All Event Hubs inside it"
echo "  - All SAS policies"
echo ""
echo "Resource group '$RESOURCE_GROUP' will NOT be deleted."
echo ""
read -p "Are you sure? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Deleting Event Hub namespace '$NAMESPACE_NAME'..."
az eventhubs namespace delete \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NAMESPACE_NAME" \
  --yes

echo ""
echo "  Done. Namespace and all contained Event Hubs have been deleted."
echo ""
echo "REMINDER: Pause your Fabric capacity in Azure Portal to stop billing."
echo "  Azure Portal > Fabric capacity > Pause"
