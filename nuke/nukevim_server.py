""" Inspired by https://pymotw.com/2/SocketServer/ """

import sys
import SocketServer
import socket
import time
import threading
import traceback
import nuke
import StringIO

class NukeVimRequestHandler(SocketServer.BaseRequestHandler):

    def __init__(self, request, client_address, server):
        SocketServer.BaseRequestHandler.__init__(self, request, client_address, server)

    def handle(self):
        tempfile_path = self.request.recv(2048)

        # Multiplex by app
        if self.server.app == "hiero":
            import hiero
            result = hiero.core.executeInMainThreadWithResult(
                self._hiero_execfile_wrapper, args=(tempfile_path))
        elif self.server.app == "nuke":
            result = nuke.executeInMainThreadWithResult(
                self._execfile, args=(tempfile_path))
        else:
            raise RuntimeError("Unknown App")

            if result is not None:
                result = result.strip()

                # Not empty...
                if len(result):
                    self.request.send(result)

            else:
                self.request.send("<No Output>")

        # notify the client that nothing was recieved
        else:
            self.request.send("recieved nothing!")

        return

    def _hiero_execfile_wrapper(self, **kwargs):
        """ Naturally hiero's executeInMainThreadWithResults sends it's args
        in as kwargs -- so use this wrapper for hiero to extract the tempfile
        path and pass it along to _execfile """
        return self._execfile(kwargs['args'])

    def _execfile(self, vimnuke_tempfile):
        """ Borrowed some ideas from here:
            pythonextensions/site-packages/foundry/ui/scripteditor/__init__.py
        """

        # Read the contents of the file
        f = open(vimnuke_tempfile)
        lines = f.readlines()
        f.close()
        text = "".join(lines)

        # prep the python commands and print em
        text = "".join(lines)
        print "# recieved from nuke.vim: %s"
        print text.strip()

        try:
            if len(lines) == 1:
                mode = 'single'
            else:
                mode = 'exec'

            code_obj = compile(text, vimnuke_tempfile, mode)
        except Exception as e:
            # If the code doesn't compile, no reason to try to exec it below!
            result = traceback.format_exc()
            print "# Result: %s\n" % result
            return result

        #Capture exec results
        oldStdOut = sys.stdout
        str_buffer = StringIO.StringIO()
        sys.stdout = str_buffer
        try:
            # Ian Thompson is a golden god
            import __main__
            exec code_obj in __main__.__dict__
        except Exception as e:
            result = traceback.format_exc()

        else:
            result = str_buffer.getvalue()

        finally:
            sys.stdout = oldStdOut

            # Print results
            print "# Result: %s\n" % result

            return result


class NukeVimServer(SocketServer.TCPServer):

    def __init__(self, server_address, handler_class=NukeVimRequestHandler):
        self.address = server_address
        SocketServer.TCPServer.__init__(self, server_address, handler_class)
        self.stop_now = False

        # Switch on nuke.env to hook up the proper hiero function and cache here
        if nuke.env['hiero']:
            self.app = "hiero"
        else:
            self.app = "nuke"

    def halt_now(self):
        """ A function to signal the server to stop and shut down.  Sets
        the stop_now variable which breaks out out of the while loop in
        serve_forever """
        self.stop_now = True

        # We seriously also have to make a fake connection to really stop
        # the server from running!
        connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        connection.connect(self.address)

    def serve_forever(self):
        """ The core execution loop for the server """
        while not self.stop_now:
            self.handle_request()

        # If you're here, stop_now has been set to true by halt_now.  Close
        # the socket but....
        self.socket.close()

        print "Server Halted."
        return

def start():
    """ The function which starts up the nuke.vim communication server """
    address = (socket.gethostname(), 10191)

    print "nukevim server: listening on %s:%s" % (address[0], address[1])
    global server
    server = NukeVimServer(address)
    server.allow_reuse_address = True

    t = threading.Thread(target=server.serve_forever)
    t.setDaemon(True) # don't hang on exit
    t.start()

def stop():
    """ The function which stops the nuke.vim communication server """
    msg = "nukevim server: halting theaded server..."
    nuke.tprint(msg)
    print msg
    server.halt_now()

def restart():
    """ A helper function used for debugging purposes """
    stop()
    time.sleep(3)
    start()

