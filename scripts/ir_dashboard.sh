#!/bin/bash
# =============================================================
# IR Lab - Live Dashboard
# Usage: watch -n 5 bash scripts/ir_dashboard.sh
# =============================================================

clear
echo "============================================================"
echo "  IR LAB - INCIDENT RESPONSE DASHBOARD"
echo "  $(date '+%Y-%m-%d %H:%M:%S UTC')"
echo "============================================================"

echo ""
echo "-- SERVICES -------------------------------------------"
for svc in auditd fail2ban ufw ir-detection; do
  status=$(systemctl is-active "$svc" 2>/dev/null)
  if [ "$status" = "active" ]; then
    echo "  [ACTIVE] $svc"
  else
    echo "  [DOWN]   $svc ($status)"
  fi
done

echo ""
echo "-- RECENT ALERTS (last 5) -----------------------------"
if [ -f /opt/ir-lab/logs/alerts.json ]; then
  tail -5 /opt/ir-lab/logs/alerts.json | python3 -c "
import sys, json
for line in sys.stdin:
  line = line.strip()
  if not line: continue
  try:
    a = json.loads(line)
    print('  [{}] [{}] src:{}'.format(
      a.get('severity','?'),
      a.get('type','?'),
      a.get('src_ip','?')
    ))
  except:
    pass
" 2>/dev/null
else
  echo "  No alerts yet."
fi

echo ""
echo "-- BLOCKED IPs ----------------------------------------"
blocked=$(sudo iptables -L INPUT -n 2>/dev/null | grep "DROP" | awk '{print $4}' | grep -v "0.0.0.0" | head -10)
if [ -n "$blocked" ]; then
  echo "$blocked" | while read ip; do echo "  [BLOCKED] $ip"; done
else
  echo "  No IPs currently blocked."
fi

echo ""
echo "-- SSH FAILED ATTEMPTS (top 5 today) ------------------"
grep "Failed password" /var/log/auth.log 2>/dev/null | \
  awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' | \
  sort | uniq -c | sort -rn | head -5 | \
  awk '{printf "  %4d attempts from %s\n", $1, $2}' || echo "  None."

echo ""
echo "-- INCIDENT REPORTS -----------------------------------"
count=$(ls /opt/ir-lab/reports/*.md 2>/dev/null | wc -l)
if [ "$count" -gt 0 ]; then
  echo "  $count report(s) generated:"
  ls -t /opt/ir-lab/reports/*.md 2>/dev/null | head -5 | \
    while read f; do echo "  $(basename $f)"; done
else
  echo "  No reports yet."
fi

echo ""
echo "============================================================"
echo "  journalctl -u ir-detection -f    (live detection log)"
echo "  tail -f /opt/ir-lab/logs/alerts.json  (JSON alerts)"
echo "  watch -n 5 bash scripts/ir_dashboard.sh  (refresh)"
echo "============================================================"
