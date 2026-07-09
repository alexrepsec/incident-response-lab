# Playbook: SSH Brute Force Attack

**Playbook ID:** PB-001  
**Version:** 1.0  
**MITRE ATT&CK:** T1110.001 - Brute Force / Password Guessing  
**Severity:** HIGH  

---

## 1. Identification

### Indicators of Compromise
- Multiple failed SSH login attempts from a single IP
- Threshold: 5 or more failed attempts within one detection cycle
- Log source: `/var/log/auth.log`
- Pattern: `Failed password for * from <IP>`

### Automated Detection
- **Script:** `detect_incident.sh` → `detect_ssh_bruteforce()`
- **Alert type:** `SSH_BRUTEFORCE`
- **Alert file:** `/opt/ir-lab/logs/alerts.json`

### Manual Verification
```bash
# Count failed SSH attempts per IP
grep "Failed password" /var/log/auth.log \
  | awk '{for(i=1;i<=NF;i++) if($i=="from") print $(i+1)}' \
  | sort | uniq -c | sort -rn

# Show last 20 failed attempts
grep "Failed password" /var/log/auth.log | tail -20

# Check Fail2ban status
sudo fail2ban-client status sshd

# Check currently blocked IPs
sudo iptables -L INPUT -n | grep DROP
```

---

## 2. Containment

### Automated (executed by respond.sh)
- [x] Block source IP via `iptables -I INPUT -s <IP> -j DROP`
- [x] Block via UFW: `ufw deny from <IP>`
- [x] Add to `/etc/hosts.deny`
- [x] Log block in `/opt/ir-lab/logs/blocked_ips.txt`

### Manual Steps
```bash
# Block IP manually
sudo iptables -I INPUT -s <ATTACKER_IP> -j DROP
sudo ufw deny from <ATTACKER_IP>
echo "ALL: <ATTACKER_IP>" | sudo tee -a /etc/hosts.deny

# Ban via Fail2ban
sudo fail2ban-client set sshd banip <ATTACKER_IP>

# Verify block is active
sudo iptables -L INPUT -n | grep <ATTACKER_IP>
```

---

## 3. Evidence Collection

### Automated (executed by respond.sh)
Evidence saved to: `/opt/ir-lab/evidence/<ALERT_ID>/`
