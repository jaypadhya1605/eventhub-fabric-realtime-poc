"""
Send Test Events to Azure Event Hub
Molina Healthcare — Member Journey Real-Time Analytics POC

Sends synthetic call center events to validate the Event Hub → Fabric pipeline.
Run this AFTER deploying the Event Hub and configuring the Fabric Eventstream.

Usage:
    pip install azure-eventhub
    python send_test_events.py

The script will prompt for your connection string, or you can set it as an
environment variable: EVENT_HUB_CONNECTION_STRING
"""

import json
import os
import random
import sys
from datetime import datetime, timezone

try:
    from azure.eventhub import EventHubProducerClient, EventData
except ImportError:
    print("ERROR: azure-eventhub package not installed.")
    print("Run: pip install azure-eventhub")
    sys.exit(1)


# ---- Configuration ----

EVENTHUB_NAME = os.getenv("EVENTHUB_NAME", "evh-callcenter-events")
EVENT_COUNT = int(os.getenv("EVENT_COUNT", "25"))

# Realistic sample data
CALL_TYPES = ["Inbound", "Outbound", "Transfer", "Callback"]
DISPOSITIONS = ["Resolved", "Escalated", "Follow-Up Required", "Voicemail", "Abandoned"]
PLAN_TYPES = ["Medicaid", "Medicare", "Marketplace", "DSNP"]
CALL_REASONS = [
    "Benefits Inquiry",
    "Claims Status",
    "Prior Authorization",
    "Provider Lookup",
    "ID Card Request",
    "Prescription Refill",
    "Appointment Scheduling",
    "Grievance Filing",
    "Enrollment Change",
    "Transportation Request",
]


def generate_event(index: int) -> dict:
    """Generate a single realistic call center event."""
    return {
        "EventTime": datetime.now(timezone.utc).isoformat(),
        "CallType": random.choice(CALL_TYPES),
        "MemberID": f"M-{random.randint(100000, 999999)}",
        "Duration": random.randint(30, 600),
        "AgentID": f"A-{random.randint(100, 500)}",
        "Disposition": random.choice(DISPOSITIONS),
        "PlanType": random.choice(PLAN_TYPES),
        "CallReason": random.choice(CALL_REASONS),
        "SatisfactionScore": random.randint(1, 5),
        "QueueWaitSeconds": random.randint(5, 300),
        "EventIndex": index,
    }


def get_connection_string() -> str:
    """Get connection string from environment or user input."""
    conn_str = os.getenv("EVENT_HUB_CONNECTION_STRING")
    if conn_str:
        return conn_str

    print("Enter your Event Hub connection string")
    print("(from Azure Portal > Event Hub namespace > Shared access policies):")
    conn_str = input("> ").strip()
    if not conn_str:
        print("ERROR: Connection string cannot be empty.")
        sys.exit(1)
    return conn_str


def main():
    print("=" * 50)
    print("  Event Hub Test Event Sender")
    print("=" * 50)
    print(f"  Event Hub:  {EVENTHUB_NAME}")
    print(f"  Events:     {EVENT_COUNT}")
    print()

    conn_str = get_connection_string()

    producer = EventHubProducerClient.from_connection_string(
        conn_str, eventhub_name=EVENTHUB_NAME
    )

    print(f"\nSending {EVENT_COUNT} test events...")

    with producer:
        batch = producer.create_batch()
        for i in range(EVENT_COUNT):
            event = generate_event(i + 1)
            try:
                batch.add(EventData(json.dumps(event)))
            except ValueError:
                # Batch is full, send and start a new one
                producer.send_batch(batch)
                batch = producer.create_batch()
                batch.add(EventData(json.dumps(event)))

        # Send remaining events
        producer.send_batch(batch)

    print(f"\n  Sent {EVENT_COUNT} events successfully!")
    print()
    print("Next steps:")
    print("  1. Go to Fabric portal > Eventhouse > KQL database")
    print("  2. Run: CallCenterEvents | take 10")
    print("  3. You should see your events within seconds")
    print()
    print("Sample event sent:")
    sample = generate_event(0)
    print(json.dumps(sample, indent=2))


if __name__ == "__main__":
    main()
