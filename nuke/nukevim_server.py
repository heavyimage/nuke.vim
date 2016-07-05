##
#  Copyright (c)        2012 sydh <sydhds at gmail dot com>
#                       All Rights Reserved
#
#  This program is free software. It comes without any warranty, to
#  the extent permitted by applicable law. You can redistribute it
#  and/or modify it under the terms of the Do What The Fuck You Want
#  To Public License, Version 2, as published by Sam Hocevar. See
#  http://sam.zoy.org/wtfpl/COPYING for more details.
##

import socket
import select
import threading
import nuke
import nukescripts

class Server():

    def __init__(self, host, port, stopEvent):

        self._stopEvent = stopEvent

        for res in socket.getaddrinfo(host, port, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):
            af, socktype, proto, canonname, sa = res

            try:
                self.s = socket.socket(af, socktype, proto)
            except socket.error, msg:
                self.s = None
                continue

            try:
                self.s.bind(sa)
                self.s.listen(1)
            except socket.error, msg:
                self.s.close()
                self.s = None
                continue

            break

        if not self.s:
            raise RuntimeError('Unable to initialise server: %s' % msg)
    def start(self):

        done = False
        while not done and not self._stopEvent.isSet():

            inr, outr, exr = select.select([self.s], [], [], 1.0)

            for s in inr:
                if s == self.s:
                    (conn, addr) = self.s.accept()
                    nuke.tprint('Connection from %s', addr)

                    data = conn.recv(1024)

                    if data == 'shutdown':
                        done = True
                    else:
                        nukescripts.utils.executeInMainThread(nuke.load, (data,))

                    conn.close()

        nuke.tprint('commandPort shutdown')

class serverThread(threading.Thread):

    def __init__(self, name, host, port):

        threading.Thread.__init__(self, name=name)
        self._stopEvent = threading.Event()
        self.host = host
        self.port = port
        self.name = name
        # prevent Nuke hang at exit
        self.daemon = True

    def run(self):
        s = Server(self.host, self.port, self._stopEvent)
        s.start()

    def stop(self):
        self._stopEvent.set()

def start(host=socket.gethostname(), port=50777):
    nuke.tprint('starting commandPort on %s:%s' % (host, port))
    server = serverThread('commandPort', host, port)
    server.start()




