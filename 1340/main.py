"""
Program: Echo Server
Author: The Dockers
Date: 2025
Description: Implement the server side of the socket
"""

import socket
import boto3
from boto3.dynamodb.conditions import Key, Attr
from datetime import datetime

SERVER_IP = "127.0.0.1"
SERVER_PORT = 1337


ddb = boto3.resource("dynamodb", region_name="us-west-2")


def log_message(string_name, SERVICE):
    table = ddb.Table("time_string")
    table.put_item(
        Item={
            "string_name": string_name,
            "timestamp": datetime.now(),
            "service": SERVICE,
        }
    )


def query_table(message):
    table = ddb.Table("time_string")
    response = table.query(
        KeyConditionExpression=Key("string_name").contains(message)
    )

    return response


def get_entry(entry):
    message = (
        f"{entry['timestamp']} ({entry['service']}): {entry['string_name']}"
    )
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
