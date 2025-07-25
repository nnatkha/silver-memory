"""
Program: Echo Server
Author: The Dockers
Date: 2025
Description: Implement the server side of the socket
"""

import socket

SERVER_IP = "0.0.0.0"
SERVER_PORT = 1337


def listen_socket(listen_address, listen_port):
    """
    Create a listening socket for the server

    Args:
        listen_address (String): IP address of server
        listen_port (Int): Listening port for server

    Returns:
        Socket: Socket that was initiated for listening
    """
    server = socket.socket()

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
        data, addr = server.recvfrom(4096)
        server.sendto(data, addr)


def main():
    """Main program logic"""
    server = listen_socket(SERVER_IP, SERVER_PORT)

    with server:
        echo(server)


if __name__ == "__main__":
    main()
