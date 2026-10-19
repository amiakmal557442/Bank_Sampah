import urllib.request, ssl, re

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = 'https://e-sampahparepare.my.id/main.dart.js'
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, context=ctx) as resp:
    data = resp.read().decode('utf-8', errors='ignore')
    matches = re.findall(r'Daftar [A-Za-z0-9_]+', data)
    print('Matches for Daftar:', set(matches))
