"""
Program: Echo Server
Author: The Dockers
Date: 2025
Description: Implement the server side of the socket
"""

import socket
import boto3, os
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime

SERVER_IP = "0.0.0.0"
SERVER_PORT = 1340


dynamo = boto3.resource(
    "dynamodb", region_name=os.getenv("AWS_REGION", "us-west-2")
)


def query_table(message):
    table = dynamo.Table("time_string")
    results = table.scan(
        FilterExpression=Attr("data").contains(message),
    )
    return results.get("Items", [])


def get_entry(entry):
    message = f"{entry.get('ts', '')} ({entry.get('sv', '')}): {entry.get('data', '')}"
    return message


def listen_socket(listen_address, listen_port):
    """
    Create a listening socket for the server

    Args:
        listen_address (String): IP address of server
        listen_port (Int): Listening port for server

    Returns:
        Socket: Socket that was initiated for listening
    """
    # server = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #socket.AF_INET,socket.SOCK_STREAM
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

        response = query_table(data.decode("utf-8"))

        for entry in response:
            message = get_entry(entry)

            conn.send(message.encode("utf-8"))

        conn.close()


def main():
    """Main program logic"""
    server = listen_socket(SERVER_IP, SERVER_PORT)

    echo(server)


if __name__ == "__main__":
    main()
