"""
Program: Echo Server
Author: The Dockers
Date: 2025
Description: Implement the server side of the socket
"""

import socket

SERVER_IP = "127.0.0.1"
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
        conn.send(data)
        conn.close()


def main():
    """Main program logic"""
    server = listen_socket(SERVER_IP, SERVER_PORT)

    echo(server)
    

if __name__ == "__main__":
    main()
