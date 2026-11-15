# @title Tiny Web Server
# @category Tools
# @kind Console program
# @where Save as server.py and run: python3 server.py, then open http://localhost:8000 in a browser on the same computer. Press Ctrl+C to stop.
# @keywords python web server, python http server, python localhost, python basehttprequesthandler
# @about Runs your own tiny website on your computer that shows a page with a visit counter.

from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

visits = {"count": 0}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/":
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Page not found")
            return
        visits["count"] += 1
        page = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>My Python Site</title></head>
<body style="font-family: sans-serif; text-align: center; margin-top: 60px">
  <h1>Hello from Python!</h1>
  <p>This page was made at {datetime.now().strftime('%H:%M:%S')}.</p>
  <p>It has been visited {visits['count']} times.</p>
</body></html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(page.encode("utf-8"))


server = HTTPServer(("localhost", 8000), Handler)
print("Server running at http://localhost:8000  (Ctrl+C to stop)")
try:
    server.serve_forever()
except KeyboardInterrupt:
    print("\nServer stopped.")
    server.server_close()
