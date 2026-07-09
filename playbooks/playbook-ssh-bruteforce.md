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

network/listening_ports.txt
network/established_connections.txt
network/iptables_rules.txt
system/auth.log
system/last_logins.txt
system/audit_today.txt

## EVIDENCE_HASHES.txt

### Manual Collection
```bash
# Export SSH failed attempts for attacker IP
grep "Failed password" /var/log/auth.log \
  | grep <ATTACKER_IP> > evidence_ssh_attempts.txt

# Export login history
last -i | head -50 >> evidence_logins.txt

# Export SSH journal
sudo journalctl -u ssh --since "1 hour ago" >> evidence_journal.txt

# Hash all evidence files
sha256sum evidence_* > evidence_hashes.txt
```

---

## 4. Eradication

```bash
# Verify no successful logins from attacker IP
grep "Accepted" /var/log/auth.log | grep <ATTACKER_IP>

# Check for new unauthorized user accounts
awk -F: '$3 >= 1000 {print $1, $3}' /etc/passwd

# Check for modified SSH authorized_keys
find /home -name "authorized_keys" -newer /etc/passwd

# Check for new cron jobs
crontab -l
ls -la /var/spool/cron/crontabs/
cat /etc/crontab
```

---

## 5. Recovery

```bash
# Enforce SSH key-only authentication
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' \
  /etc/ssh/sshd_config
sudo systemctl restart ssh

# Rotate SSH host keys if needed
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server

# Remove IP block after investigation (optional)
sudo iptables -D INPUT -s <ATTACKER_IP> -j DROP
sudo ufw delete deny from <ATTACKER_IP>
```

- [ ] Rotate credentials if compromise is suspected
- [ ] Patch any exploited vulnerabilities
- [ ] Update detection threshold if needed
- [ ] Notify stakeholders

---

## 6. Timeline Template

| Time (UTC) | Event |
|---|---|
| HH:MM:SS | Attack initiated from `<ATTACKER_IP>` |
| HH:MM:SS | Detection engine triggered (threshold reached) |
| HH:MM:SS | Automated response executed |
| HH:MM:SS | IP blocked via iptables, UFW, hosts.deny |
| HH:MM:SS | Evidence collected and hashed |
| HH:MM:SS | Incident report generated |

---

## 7. Lessons Learned

| Question | Answer |
|---|---|
| How was the attack detected? | Automated threshold detection in detect_incident.sh |
| Was detection timely? | Within 30 seconds of threshold breach |
| Did containment succeed? | Yes — IP blocked across 3 layers automatically |
| Any gaps identified? | Document here after each incident |

---

*Playbook version 1.0 — IR Lab by alexrepsec*
