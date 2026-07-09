# Playbook: Port Scan / Network Reconnaissance

**Playbook ID:** PB-002  
**Version:** 1.0  
**MITRE ATT&CK:** T1046 - Network Service Scanning  
**Severity:** MEDIUM / HIGH  

---

## 1. Identification

### Indicators of Compromise
- Rapid SYN connections to multiple ports from the same source IP
- Threshold: 10 or more simultaneous SYN_RECV connections
- nmap or similar tool execution detected via auditd

### Automated Detection
- **Script:** `detect_incident.sh` → `detect_port_scan()`
- **Alert type:** `PORT_SCAN`
- **Alert file:** `/opt/ir-lab/logs/alerts.json`

### Manual Verification
```bash
# View current SYN connections per source IP
ss -tn state syn-recv \
  | awk '{print $5}' | cut -d: -f1 \
  | sort | uniq -c | sort -rn

# Check auditd for nmap or scan tools
sudo ausearch -k port_scan -ts today

# View recent connections from a specific IP
ss -tn | grep <ATTACKER_IP>

# Check kernel logs
dmesg | tail -50
```

---

## 2. Containment

### Automated (executed by respond.sh)
- [x] Block source IP via iptables DROP
- [x] Log block in `/opt/ir-lab/logs/blocked_ips.txt`

### Manual Steps
```bash
# Full block
sudo iptables -I INPUT -s <ATTACKER_IP> -j DROP
sudo ufw deny from <ATTACKER_IP>

# Rate limit instead of full block (gentler option)
sudo iptables -I INPUT -s <ATTACKER_IP> \
  -m limit --limit 5/minute --limit-burst 10 -j ACCEPT
sudo iptables -I INPUT -s <ATTACKER_IP> -j DROP
```

---

## 3. Evidence Collection

```bash
# Capture current listening ports
ss -tulpn > /opt/ir-lab/evidence/ports_listening.txt

# Capture active connections
ss -tn state established > /opt/ir-lab/evidence/connections.txt

# Packet capture for 60 seconds
sudo tcpdump -i ens33 -w /opt/ir-lab/evidence/capture.pcap \
  host <ATTACKER_IP> &
sleep 60 && kill %1

# auditd events for scan tools
sudo ausearch -k port_scan -ts today \
  > /opt/ir-lab/evidence/auditd_scan.txt
```

---

## 4. Assessment

A port scan alone is **reconnaissance**, not a direct attack. Evaluate:

- What ports did the scan discover as open?
- Was the scan followed by exploitation attempts?
- Is the source IP internal (insider threat) or external?
- What tools were used? (nmap, masscan, custom)

```bash
# Check what ports are exposed
sudo ufw status numbered
sudo ss -tulpn

# Check if exploitation followed the scan
grep <ATTACKER_IP> /var/log/auth.log | tail -50
```

---

## 5. Recovery

```bash
# Review and reduce attack surface
sudo ufw status numbered

# Disable unnecessary services
sudo systemctl disable <service>
sudo systemctl stop <service>

# Verify only required ports are open
sudo ss -tulpn | grep LISTEN
```

- [ ] Close unnecessary open ports
- [ ] Review firewall rules
- [ ] Consider deploying a honeypot port
- [ ] Update network documentation

---

## 6. Timeline Template

| Time (UTC) | Event |
|---|---|
| HH:MM:SS | Port scan initiated from `<ATTACKER_IP>` |
| HH:MM:SS | Detection engine triggered |
| HH:MM:SS | Source IP blocked via iptables |
| HH:MM:SS | Evidence collected |
| HH:MM:SS | Assessment completed |

---

*Playbook version 1.0 — IR Lab by alexrepsec*
