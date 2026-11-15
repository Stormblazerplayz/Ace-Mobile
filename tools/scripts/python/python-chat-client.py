# @title Local Chat Client
# @category Tools
# @kind Console program
# @where Save as chat_client.py and run: python3 chat_client.py after starting python-chat-server. Type the server computer's IP address (or localhost).
# @keywords python chat client, python socket client, python connect to server, python send messages
# @about Joins the local chat server so you can send and receive messages with others on your network.

import socket
import threading

host = input("Server address (Enter for localhost): ").strip() or "localhost"
name = input("Your chat name: ").strip() or "Guest"

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.connect((host, 5050))
except OSError as error:
    raise SystemExit(f"Couldn't connect: {error}")
sock.sendall(name.encode("utf-8"))


def listen():
    # Runs in the background so messages show up while you're typing
    while True:
        try:
            data = sock.recv(1024)
        except OSError:
            break
        if not data:
            print("\nThe server closed.")
            break
        print("\r" + data.decode("utf-8").rstrip() + "\n> ", end="", flush=True)


threading.Thread(target=listen, daemon=True).start()
print("Connected! Type messages and press Enter. Type /quit to leave.")
while True:
    message = input("> ")
    if message == "/quit":
        break
    if message:
        sock.sendall((message + "\n").encode("utf-8"))
sock.close()
