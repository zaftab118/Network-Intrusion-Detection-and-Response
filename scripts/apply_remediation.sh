#!/bin/bash
# ==============================================================================
# Script: apply_remediation.sh
# Purpose: Block malicious external IP and port at the gateway FORWARD chain
# Reference: Lab 11.1.7 Network Intrusion Detection
# ==============================================================================

TARGET_IP="209.165.202.133"
TARGET_PORT="6666"

echo "[*] Checking existing iptables FORWARD rules..."
iptables -L FORWARD -n -v

echo "[*] Applying DROP rule for destination ${TARGET_IP}:${TARGET_PORT}..."
iptables -I FORWARD -p tcp -d "$TARGET_IP" --dport "$TARGET_PORT" -j DROP

if [ $? -eq 0 ]; then
    echo "[+] Remediation applied successfully."
else
    echo "[-] Error: Failed to insert iptables rule."
    exit 1
fi

echo "[*] Updated FORWARD chain:"
iptables -L FORWARD -n -v --line-numbers
