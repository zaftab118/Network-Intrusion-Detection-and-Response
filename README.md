# Network-Intrusion-Detection-and-Response

Enterprise network defense simulation using Mininet, Snort NIDS, tcpdump, and iptables to detect malware traffic and enforce perimeter containment.

---

## Project Overview
In a Security Operations Center (SOC), identifying suspicious traffic requires validating alerts against raw network payloads and rapidly implementing containment rules to prevent compromise. In this lab environment:
- Simulated an enterprise network environment featuring a DMZ, internal workstation subnets, edge routing, and an external attacker subnet using Mininet.
- Monitored real-time signature alerts via Snort NIDS when an internal host initiated a file retrieval against an unauthorized web server.
- Executed packet captures using `tcpdump` to preserve evidentiary PCAP data.
- Hardened the perimeter by writing and verifying stateful `iptables` FORWARD rules to terminate threat communication.

---

## Architecture & Network Topology
```text
[ Attacker (h9) / Malicious Server (h10) ]
│ Subnets: 198.51.100.0/24 & 209.165.202.128/27
▼
[ ISP Router (r4) ]
│ IP: 209.165.201.1
▼
[ Gateway / Firewall / IDS Router (r1) ] ── (Snort NIDS + iptables)
│ IPs: 209.165.201.11 | 192.168.0.1 | 192.168.1.1 | 209.165.200.225
┌───┴────────────────────────────────────────┐
▼                                            ▼
[ DMZ Servers (h5, h6) ]             [ Internal Subnets (h1-h4, h7-h8) ]
Subnet: 209.165.200.224/27           Subnets: 192.168.0.0/24 & 192.168.1.0/24
```

---

## 🛠️ Security Tools & Environment
- **Network Emulation:** Mininet (Python/OpenFlow topology simulation)
- **NIDS Engine:** Snort 2.9 (Signature matching and live alert logging)
- **Packet Telemetry:** `tcpdump` / Wireshark (Full packet capture and inspection)
- **Firewall & Filtering:** Linux Netfilter (`iptables`)
- **Web Services:** Nginx (HTTP delivery over custom TCP port `6666`)

---

## 🔍 Investigation & Remediation Workflow

### 1. Alert Generation & Live NIDS Monitoring
From the boundary gateway router (`r1`), initiated real-time alert monitoring across the Snort alert log:
```bash
tail -f /var/log/snort/alert
```

When DMZ host `h5` (`209.165.200.235`) retrieved the simulated payload `W32.Nimda.Amm.exe` from external server `h10` (`209.165.202.133`) over TCP port `6666`, Snort flagged the signature in real time:

09/14-01:52:13.241351 [**] [1:1000003:0] Malicious Server Hit! [**] [Priority: 0]
{TCP} 209.165.200.235:47282 -> 209.165.202.133:6666

### 2. Forensic PCAP Preservation
To capture the full transport exchange for malware analysis and protocol validation, ran `tcpdump` in the background on interface `h5-eth0`:
```bash
tcpdump -i h5-eth0 -w nimda.download.pcap &
```
The resulting capture file (`nimda.download.pcap`, ~371 KB) captured the full TCP three-way handshake, HTTP GET request, and binary payload transfer.

### 3. Perimeter Containment via iptables
By default, router `r1` permitted all forwarded traffic (`Chain FORWARD - policy ACCEPT`). To stop subsequent connections to the offending server, added a packet filtering rule to the head of the `FORWARD` chain:
```bash
iptables -I FORWARD -p tcp -d 209.165.202.133 --dport 6666 -j DROP
```

### 4. Verification & Efficacy Testing
- **Egress Retest**: Attempted another file download from `h5` using `wget 209.165.202.133:6666/W32.Nimda.Amm.exe`. The connection timed out immediately.
- **Rule Counter Verification**: Ran `iptables -L -v` and confirmed matching packet counters incremented on the target rule (`DROP tcp any anywhere 209.165.202.133 tcp dpt:6666`).

---

## Key Takeaways & Defense-in-Depth Analysis
- **Signature Alerting vs. Active Enforcement**: An IDS only flags malicious payloads; coupling alert pipelines with stateful firewall policies or automated IPS playbooks is necessary to prevent malware delivery.
- **Non-Standard Egress Ports**: Malicious actors often host C2 and malware delivery infrastructure on non-standard ports (e.g., port 6666) to bypass default firewall filters. Egress inspection and default-deny policies prevent unvetted outbound requests.
