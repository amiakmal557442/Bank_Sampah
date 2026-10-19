import urllib.request, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

for path in ['/', '/index.html', '/flutter_bootstrap.js', '/flutter_service_worker.js']:
    url = f'https://e-sampahparepare.my.id{path}'
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, context=ctx) as resp:
        print(f"=== {path} ===")
        print("Server:", resp.headers.get('Server'))
        print("Cache-Control:", resp.headers.get('Cache-Control'))
        print("CF-Cache-Status:", resp.headers.get('CF-Cache-Status'))
        print("X-Cache:", resp.headers.get('X-Cache'))
        print("Last-Modified:", resp.headers.get('Last-Modified'))
