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
import sys
import socket
import traceback
import threading
import StringIO
import nuke

SERVERNAME = "nukevim_server"

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

    def _execfile(self, vimnuke_tempfile):
        """ Borrowed from here: pythonextensions/site-packages/foundry/ui/scripteditor/__init__.py """

        import __main__

        # Read the contents of the file
        f = open(vimnuke_tempfile)
        lines = f.readlines()
        f.close()
        text = "".join(lines)

        #Compile
        result = None
        runError = False

        try:
            if len(lines) == 1:
                mode = 'single'
            else:
                mode = 'exec'
            print "going with %s" % mode
            code_obj = compile(text, '<string>', mode)
            compiled = True
        except Exception as e:
            result = traceback.format_exc()
            runError = True
            compiled = False

        oldStdOut = sys.stdout
        if compiled:
            #Override stdout to capture exec results
            buffer = StringIO.StringIO()
            sys.stdout = buffer
            try:
                # Ian Thompson is a golden god
                exec code_obj in __main__.__dict__
            except Exception as e:
                runError = True
                result = traceback.format_exc()
            else:
                result = buffer.getvalue()
        sys.stdout = oldStdOut

        print ("Code from nuke.vim: \n%s# Result: \n"
               "%s\n" % (text, result))
        
        return result
    


    def start(self):
        while 1:
            client, address = self.s.accept()
            try:
                tempfile_path = client.recv(4096)
                if tempfile_path:
                    print "tempfile_path: %s" % tempfile_path

                    result = nuke.executeInMainThreadWithResult(
                        self._execfile, args=(tempfile_path))

                    print "sending result: '%s'" % result

                    client.send(result or "<no output>")

            except SystemExit:
                client.send('SERVER: Shutting down...')
                raise
            finally:
                client.close()

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
    nuke.tprint("nukevim server: listening on %s:%s" % (host, port))
    server = serverThread(SERVERNAME, host, port)
    server.start()

def stop():
    nuke.tprint("nukevim server: halting server")
    for t in threading.enumerate():
        if t.getName() == SERVERNAME:
            t.stop()

def restart():
    stop()
    start()


