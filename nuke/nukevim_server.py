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
    """ Our Handler """

    def __init__(self, request, client_address, server):
        SocketServer.BaseRequestHandler.__init__(self, request,
                                                 client_address, server)

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

        # Send back the output or <No Output>
        if result is not None and len(result):
            self.request.send(result.strip())

        else:
            self.request.send("<No Output>")

    def _hiero_execfile_wrapper(self, **kwargs):
        """ Naturally hiero's executeInMainThreadWithResults sends it's args
        in as kwargs -- so use this wrapper for hiero to extract the tempfile
        path and pass it along to _execfile """
        return self._execfile(kwargs['args'])

    def _execfile(self, vimnuke_tempfile):
        """ Give the path to some python code, compile it and execute it in
        the script editor's context.  Return any output. Borrowed some ideas
        from here:
            pythonextensions/site-packages/foundry/ui/scripteditor/__init__.py
        """

        # Read the contents of the file
        with open(vimnuke_tempfile) as tempfile:
            lines = tempfile.readlines()

        # prep the python commands and print em
        text = "".join(lines)
        print "# recieved from nuke.vim: %s"
        print text.strip()

        # Attempt compliation
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

        # Assuming compilation worked, exec the code in the same context as
        # the script editor and inside a StringIO buffer so we can display
        # the results

        orig_stdout = sys.stdout
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

        # make sure that whatever happens we restore stdout
        finally:
            sys.stdout = orig_stdout

        # Make the style of the nuke script editor
        print "# Result: %s\n" % result

        return result


class NukeVimServer(SocketServer.TCPServer):
    """ Our TCP Server subclass """

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

    def serve_forever(self, poll_interval=0.25):
        """ The core execution loop for the server """
        while not self.stop_now:
            self.handle_request()

        # If you're here, stop_now has been set to true by halt_now.  Close
        # the socket but....
        self.socket.close()

        print "Server Halted."
        return

NUKEVIM_SERVER = None

def start():
    """ The function which starts up the nuke.vim communication server """
    address = (socket.gethostname(), 10191)

    print "nuke.vim server: listening on %s:%s" % (address[0], address[1])
    try:
        global NUKEVIM_SERVER
        NUKEVIM_SERVER = NukeVimServer(address)
        NUKEVIM_SERVER.allow_reuse_address = True

        thread = threading.Thread(target=NUKEVIM_SERVER.serve_forever)
        thread.setDaemon(True) # don't hang on exit
        thread.start()

    # Don't block startup...
    except socket.error as ser:
        print "Error: can't start nuke.vim server: %s" % str(ser)

def stop():
    """ The function which stops the nuke.vim communication server """
    msg = "nuke.vim server: halting theaded server..."
    nuke.tprint(msg)
    print msg
    NUKEVIM_SERVER.halt_now()

def restart():
    """ A helper function used for debugging purposes """
    stop()
    time.sleep(3)
    start()

