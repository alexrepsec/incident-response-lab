#!/bin/bash
# =============================================================
# IR Lab - Deploy Scripts as systemd Service
# Run after setup_environment.sh
# Usage: sudo bash scripts/deploy_ir_scripts.sh
# =============================================================

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/deploy_ir_scripts.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/ir-lab"

echo "[1/3] Copying scripts to $INSTALL_DIR..."
cp "$SCRIPT_DIR/detection/detect_incident.sh" $INSTALL_DIR/scripts/detection/
cp "$SCRIPT_DIR/response/respond.sh"          $INSTALL_DIR/scripts/response/
chmod +x $INSTALL_DIR/scripts/detection/detect_incident.sh
chmod +x $INSTALL_DIR/scripts/response/respond.sh
echo "  Scripts deployed."

echo "[2/3] Installing systemd service..."
cat > /etc/systemd/system/ir-detection.service << 'EOF'
[Unit]
Description=IR Lab - Incident Detection Engine
After=network.target auditd.service
Wants=auditd.service

[Service]
Type=simple
ExecStart=/bin/bash /opt/ir-lab/scripts/detection/detect_incident.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=ir-detection

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ir-detection
systemctl start ir-detection
echo "  Service installed and started."

echo "[3/3] Verifying..."
systemctl is-active ir-detection && echo "  ir-detection: ACTIVE" || echo "  ir-detection: FAILED"

echo ""
echo "============================================================"
echo "  Deployment complete!"
echo "  Live logs:  journalctl -u ir-detection -f"
echo "  Alerts:     tail -f /opt/ir-lab/logs/alerts.json"
echo "  Dashboard:  bash scripts/ir_dashboard.sh"
echo "============================================================"
