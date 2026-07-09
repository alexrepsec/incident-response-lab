#!/bin/bash
# =============================================================
# IR Lab - Environment Setup Script
# Run on VM1 (Ubuntu Server) as root
# Usage: sudo bash scripts/setup_environment.sh
# =============================================================
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo bash scripts/setup_environment.sh"
  exit 1
fi

echo "============================================================"
echo "  IR Lab - Environment Setup"
echo "  VM1: Ubuntu Server 22.04 (Defender)"
echo "============================================================"

echo "[1/6] Updating system..."
apt-get update -qq && apt-get upgrade -y -qq

echo "[2/6] Installing required packages..."
apt-get install -y -qq \
  auditd \
  audispd-plugins \
  fail2ban \
  ufw \
  net-tools \
  nmap \
  tcpdump \
  curl \
  wget \
  jq \
  git \
  tmux \
  htop \
  sysstat \
  lsof \
  netcat-openbsd \
  iptables \
  rsyslog \
  python3 \
  python3-pip

echo "[3/6] Configuring auditd..."
cat > /etc/audit/rules.d/ir-lab.rules << 'EOF'
-D
-b 8192
-f 1
-w /etc/passwd -p wa -k identity_changes
-w /etc/shadow -p wa -k identity_changes
-w /etc/sudoers -p wa -k sudo_changes
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /var/log/auth.log -p wa -k auth_log
-w /var/spool/cron -p wa -k crontab_changes
-w /etc/crontab -p wa -k crontab_changes
-a always,exit -F arch=b64 -S connect -k network_connect
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/wget -k suspicious_download
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/curl -k suspicious_download
-a always,exit -F arch=b64 -S execve -F path=/bin/nc -k netcat_usage
-a always,exit -F arch=b64 -S execve -F path=/usr/bin/nmap -k port_scan
-a always,exit -F arch=b64 -S chmod,chown -k permission_changes
EOF
augenrules --load
systemctl enable auditd
systemctl restart auditd
echo "  auditd configured."

echo "[4/6] Configuring Fail2ban..."
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 7200
EOF
systemctl enable fail2ban
systemctl restart fail2ban
echo "  Fail2ban configured."

echo "[5/6] Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
echo "  UFW configured."

echo "[6/6] Creating IR Lab directory structure..."
mkdir -p /opt/ir-lab/{scripts/{detection,response},logs,evidence/{network,processes,files,system},reports,quarantine}
chmod 750 /opt/ir-lab
chmod 700 /opt/ir-lab/evidence
chown -R $SUDO_USER:$SUDO_USER /opt/ir-lab
echo "  Directories created."

echo ""
echo "============================================================"
echo "  Setup complete!"
echo "  Next step: sudo bash scripts/deploy_ir_scripts.sh"
echo "============================================================"
