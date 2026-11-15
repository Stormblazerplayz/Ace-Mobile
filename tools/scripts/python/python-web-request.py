# @title Download a Web Page
# @category Tools
# @kind Console program
# @where Save as fetch_page.py and run: python3 fetch_page.py (needs internet).
# @keywords python web request, python urllib, python download web page, python http get, python page title
# @about Downloads a web page with urllib (built into Python) and shows its status, size and title.

import re
import urllib.error
import urllib.request

url = input("Web address (Enter for https://example.com): ").strip() or "https://example.com"
if not url.startswith(("http://", "https://")):
    url = "https://" + url

# Some sites like to know what program is asking, so we send a simple name
request = urllib.request.Request(url, headers={"User-Agent": "python-learning-script"})
try:
    with urllib.request.urlopen(request, timeout=10) as response:
        status = response.status
        html = response.read().decode("utf-8", errors="replace")
except urllib.error.HTTPError as error:
    raise SystemExit(f"The site answered with an error: {error.code}")
except urllib.error.URLError as error:
    raise SystemExit(f"Couldn't reach the site: {error.reason}")

match = re.search(r"<title[^>]*>(.*?)</title>", html, re.IGNORECASE | re.DOTALL)
title = match.group(1).strip() if match else "(no title)"
links = re.findall(r'href="(https?://[^"]+)"', html)

print("Status code:", status)
print("Size:", len(html), "characters")
print("Title:", title)
print(f"Found {len(links)} links. The first few:")
for link in links[:5]:
    print("  ", link)
