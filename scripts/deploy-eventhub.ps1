# =============================================================================
# Azure Event Hubs Deployment Script (PowerShell)
# Molina Healthcare — Member Journey Real-Time Analytics POC
# =============================================================================

param(
    [string]$ResourceGroup = "rg-molina-fabric-poc",
    [string]$Location = "westus3",
    [string]$NamespaceName = "evhns-molina-memberjourney-poc",
    [string]$EventHubName = "evh-callcenter-events",
    [string]$SasPolicyName = "molina-fabric-send-listen",
    [int]$PartitionCount = 4,
    [int]$MaxThroughputUnits = 5,
    [int]$RetentionHours = 24
)

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Event Hubs Deployment for Fabric POC" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:"
Write-Host "  Resource Group:     $ResourceGroup"
Write-Host "  Location:           $Location"
Write-Host "  Namespace:          $NamespaceName"
Write-Host "  Event Hub:          $EventHubName"
Write-Host "  Partitions:         $PartitionCount"
Write-Host "  Max TU:             $MaxThroughputUnits"
Write-Host ""

# ---- Step 1: Register provider ----
Write-Host "[1/6] Registering Microsoft.EventHub provider..." -ForegroundColor Yellow
az provider register --namespace Microsoft.EventHub 2>$null
Write-Host "  Done" -ForegroundColor Green

# ---- Step 2: Create resource group ----
Write-Host "[2/6] Creating resource group '$ResourceGroup'..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location --output none
Write-Host "  Done" -ForegroundColor Green

# ---- Step 3: Create namespace ----
Write-Host "[3/6] Creating Event Hubs namespace '$NamespaceName'..." -ForegroundColor Yellow
az eventhubs namespace create `
  --resource-group $ResourceGroup `
  --name $NamespaceName `
  --location $Location `
  --sku Standard `
  --capacity 1 `
  --enable-auto-inflate true `
  --maximum-throughput-units $MaxThroughputUnits `
  --output none
Write-Host "  Done (Standard tier, auto-inflate to $MaxThroughputUnits TU)" -ForegroundColor Green

# ---- Step 4: Create Event Hub ----
Write-Host "[4/6] Creating Event Hub '$EventHubName'..." -ForegroundColor Yellow
az eventhubs eventhub create `
  --resource-group $ResourceGroup `
  --namespace-name $NamespaceName `
  --name $EventHubName `
  --partition-count $PartitionCount `
  --cleanup-policy Delete `
  --retention-time $RetentionHours `
  --output none
Write-Host "  Done ($PartitionCount partitions, ${RetentionHours}h retention)" -ForegroundColor Green

# ---- Step 5: Create SAS policy ----
Write-Host "[5/6] Creating SAS policy '$SasPolicyName'..." -ForegroundColor Yellow
az eventhubs namespace authorization-rule create `
  --resource-group $ResourceGroup `
  --namespace-name $NamespaceName `
  --name $SasPolicyName `
  --rights Send Listen `
  --output none
Write-Host "  Done (Send + Listen)" -ForegroundColor Green

# ---- Step 6: Get connection string ----
Write-Host "[6/6] Retrieving connection string..." -ForegroundColor Yellow
$connectionString = az eventhubs namespace authorization-rule keys list `
  --resource-group $ResourceGroup `
  --namespace-name $NamespaceName `
  --name $SasPolicyName `
  --query primaryConnectionString `
  --output tsv

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Connection String:" -ForegroundColor Green
Write-Host "  $connectionString"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Go to https://app.fabric.microsoft.com"
Write-Host "  2. Create Eventhouse > Eventstream > Connect Event Hub"
Write-Host "  3. Run: python scripts/send_test_events.py"
Write-Host "  4. Verify data in KQL database"
Write-Host "  5. Create Real-Time Dashboard"
Write-Host ""
