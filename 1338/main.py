"""
Program: Echo Server
Author: The Dockers
Date: 2025
Description: Implement the server side of the socket
"""

import socket
import boto3
from datetime import datetime

SERVER_IP = "0.0.0.0"
SERVER_PORT = 1338
SERVICE = "ohce"


ddb = boto3.resource("dynamodb", region_name="us-west-2")


def log_message(string_name):
    table = ddb.Table("time_string")
    table.put_item(
        Item={
            "string_name": string_name,
            "timestamp": datetime.now(),
            "service": SERVICE,
        }
    )


def listen_socket(listen_address, listen_port):
    """
    Create a listening socket for the server

    Args:
        listen_address (String): IP address of server
        listen_port (Int): Listening port for server

    Returns:
        Socket: Socket that was initiated for listening
    """
    #server = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #socket.AF_INET,socket.SOCK_STREAM
    server = socket.socket()
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    server.bind((listen_address, listen_port))

    server.listen(0)

    return server


def echo(server: socket.socket):
    """
    Receive message and echo it back

    Args:
        server (socket.socket): Echo message back
    """
    while True:
        conn, addr = server.accept()
        data = conn.recv(4096)
        log_message(data.decode("utf-8"))
        # reverse message
        reversed_data = data[::-1]
        conn.send(reversed_data)
        conn.close()


def main():
    """Main program logic"""
    server = listen_socket(SERVER_IP, SERVER_PORT)

    echo(server)
    

if __name__ == "__main__":
    main()
