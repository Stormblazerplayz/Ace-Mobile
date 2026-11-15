# @title Website Up Checker
# @category Tools
# @kind Console program
# @where Save as site_check.py and run: python3 site_check.py (needs internet). Edit the SITES list to check your favorites.
# @keywords python website checker, python is site down, python response time, python status code check
# @about Checks if a list of websites are up and how fast each one answers.

import time
import urllib.error
import urllib.request

SITES = ["https://www.python.org", "https://www.wikipedia.org", "https://example.com"]


def check(url):
    request = urllib.request.Request(url, headers={"User-Agent": "python-learning-script"})
    start = time.perf_counter()
    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    except (urllib.error.URLError, TimeoutError) as error:
        return f"DOWN  ({error})"
    ms = (time.perf_counter() - start) * 1000
    return f"{'UP' if status < 400 else 'ERROR'}  status {status}, {ms:.0f} ms"


extra = input("Add another site to check (or press Enter): ").strip()
if extra:
    SITES.append(extra if extra.startswith("http") else "https://" + extra)

for site in SITES:
    print(f"{site:<32} {check(site)}")
