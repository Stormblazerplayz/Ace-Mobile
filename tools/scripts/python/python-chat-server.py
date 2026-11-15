# @title Local Chat Server
# @category Tools
# @kind Console program
# @where Save as chat_server.py and run: python3 chat_server.py on one computer. Then run python-chat-client on the same Wi-Fi to join. Ctrl+C stops it.
# @keywords python chat server, python socket server, python threading sockets, python lan chat
# @about A tiny chat room server for your home network: everyone who connects sees each other's messages.

import socket
import threading

HOST, PORT = "0.0.0.0", 5050  # 0.0.0.0 means "accept connections from this network"
clients = []
lock = threading.Lock()


def broadcast(message, sender=None):
    with lock:
        for client in clients:
            if client is not sender:
                try:
                    client.sendall(message.encode("utf-8"))
                except OSError:
                    pass


def handle(client, address):
    name = client.recv(1024).decode("utf-8").strip() or str(address[0])
    print(f"{name} joined from {address[0]}")
    broadcast(f"* {name} joined the chat\n")
    try:
        while True:
            data = client.recv(1024)
            if not data:  # empty means they disconnected
                break
            broadcast(f"{name}: {data.decode('utf-8')}", sender=client)
    except ConnectionResetError:
        pass
    with lock:
        clients.remove(client)
    client.close()
    broadcast(f"* {name} left the chat\n")
    print(f"{name} left")


server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen()
print(f"Chat server running on port {PORT}. This computer's name is {socket.gethostname()}.")
try:
    while True:
        client, address = server.accept()
        with lock:
            clients.append(client)
        threading.Thread(target=handle, args=(client, address), daemon=True).start()
except KeyboardInterrupt:
    print("\nServer closed.")
    server.close()
