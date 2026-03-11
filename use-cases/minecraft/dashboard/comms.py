import socket
import json

HOST = "127.0.0.1"
PORT = 5000

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect((HOST, PORT))

def send_event(event):
    message = json.dumps(event) + "\n"
    client.sendall(message.encode())