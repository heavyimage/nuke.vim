"""
"
" Coypright 2009, 2013-2014 Stefan Goebel - <vimya /at/ subtype /dot/ de>.
"
" This program is free software: you can redistribute it and/or modify it under the terms of the
" GNU General Public License as published by the Free Software Foundation, either version 3 of the
" License, or (at your option) any later version.
"
" This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
" even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
" General Public License for more details.
"
" You should have received a copy of the GNU General Public License along with this program. If
" not, see <http://www.gnu.org/licenses/>.
"
"""

"""
"
" Vimya 0.5 - Execute buffer contents as MEL or Python scripts in Autodesk Maya.
"
" Help is available in doc/nukevim.txt or from within Vim:
"
"   :help vimya
"
" Help for all the Python functions can also be accessed in Vim the Python way:
"
"   :py help (<function>)
"
"""

if exists('g:nukevimLoaded') || &compatible || ! has('python')
    finish
endif
let g:nukevimLoaded = '0.5'

"""
" Configuration variables:
"""

function NukevimSetConfig(name, default)
    if ! exists('g:nukevim' . a:name)
        let {'g:nukevim' . a:name} = a:default
    endif
endfunction

call NukevimSetConfig( 'DefaultFiletype',  'python'      )
call NukevimSetConfig( 'Host',             'nomad.local' )
call NukevimSetConfig( 'Port',             50777         )
call NukevimSetConfig( 'Socket',           ''            )
call NukevimSetConfig( 'SplitBelow',       &splitbelow   )
call NukevimSetConfig( 'TempDir',          ''            )
call NukevimSetConfig( 'Timeout',          5.0           )

"""
" Mappings:
"""

if ! hasmapto (':py nukevimRun')
    nnoremap <leader>sn :py nukevimRun()<cr>
    vnoremap <leader>sn :py nukevimRun()<cr>
    nnoremap <leader>sb :py nukevimRun(forceBuffer = True)<cr>
    vnoremap <leader>sb :py nukevimRun(forceBuffer = True)<cr>
endif

"""
" Commands:
"""

command -nargs=0 NukevimRun     :py nukevimRun()
command -nargs=0 NukevimBuffer  :py nukevimRun(forceBuffer = True    )
command -nargs=1 NukevimSend    :py nukevimSend([<q-args>]            )

"""
" Main stuff (most of it is Python):
"""

autocmd VimLeavePre * py __nukevimRemoveTempFiles()

python << EOP

import os
import platform
import socket
import tempfile
import time
import vim

# Global variables:

# Contains all the temporary python files created
__nukevimTempFiles = []

def __nukevimRemoveTempFiles():

    """Remove all temporary files.

    __nukevimRemoveTempFiles() : None

    This function will be called automatically when leaving Vim. It will try to delete all the
    temporary files created during the session. There is no error handling, if deleting a file
    fails, the file will be left on disk.

    This function does not return anything.
    """

    global __nukevimTempFiles

    for tempFile in __nukevimTempFiles:
        if os.path.isfile(tempFile):
            try:
                os.unlink(tempFile)
            except:
                pass

def __nukevimMsg(message):

    """Print (and logs, via :messages) a vim message.

    __nukevimMsg(message) : True

    This function will print the message in Vim's message area

    It will always return True.
    """

    vim.command('echomsg "%s"' % __nukevimEscape(message, '\\"'))

    return True

def __nukevimError(message):

    """Print an error message.

    __nukevimError(message) : False

    This function will print the error message in Vim's message area, using the appropriate
    error highlighting.

    It will always return False.
    """

    vim.command('echohl ErrorMsg | echo "%s" | echohl None' % __nukevimEscape(message, '\\"'))

    return False

def __nukevimEscape(string, characters):

    """Escape specified characters in a string with backslash.

    __nukevimEscape(string, characters) : str

    Works like Vim's escape() function. Every occurrence of one of the characters in the characters
    parameter inside the string will be replaced by '\' + character. The backslash itself has to be
    included as the first character in the characters parameter if it also should be escaped!

    Returns the resulting string.
    """

    for character in characters:
        string = string.replace(character, '\\%s' % character)

    return string

def __nukevimFilenameEscape(filename):

    """Apply Vim's fnameescape() function to a string.

    __nukevimFilenameEscape(string) : str

    This function may be used to apply Vim's fnameescape() function to the supplied parameter.

    Returns the escaped string.
    """

    return vim.eval('fnameescape("%s")' % __nukevimEscape(filename, '\\"'))

def __nukevimFixPath(filename):

    """Replace all backslashes in the file name with slashes on Windows platforms.

    __nukevimFixPath(filename) : str

    Replaces all backslashes in the file name with slashes on Windows platforms.

    Returns the resulting string.
    """

    if platform.system() == 'Windows':
        return filename.replace('\\', '/')
    else:
        return filename

def nukevimSend(commands):

    """Send commands to Nuke's command port.

    nukevimSend(commands) : int

    This function will open a connection to Nuke's command port (as configured), and send the
    commands - which must be a list of one or more strings - to Nuke. A newline will be appended
    to every command automatically. Commands will be sent in the order they appear in the list.

    Socket exceptions will be caught and an appropriate error message will be displayed. After an
    exception, no attempt will be made to send any more commands from the list.

    Returns the number of commands successfully sent to Nuke.
    """

    socketPath =      vim.eval('g:nukevimSocket' )
    timeout    =      vim.eval('g:nukevimTimeout')
    host       =      vim.eval('g:nukevimHost'   )
    port       =  int(vim.eval('g:nukevimPort'   ))

    try:
        if socketPath != '':
            connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        else:
            connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        if timeout == '':
            connection.settimeout(None)
        else:
            connection.settimeout(float(timeout))
    except socket.error as e:
        __nukevimError('Could not initialize the socket: %s' % str(e))
        return 0

    try:
        if socketPath != '':
            connection.connect(socketPath)
        else:
            connection.connect((host, port))
    except socket.error as e:
        __nukevimError('Could not connect to command port: %s' % str(e))
        return 0

    sent = 0

    try:
        try:
            for command in commands:
                connection.send('%s\n' % command)
                sent = sent + 1
        except socket.error as e:
            __nukevimError('Sending a command failed: %s' % str(e))
    finally:
        connection.shutdown(socket.SHUT_WR)
        connection.close()

    return sent

def nukevimRun(forceBuffer = False):

    """Sent (partial) buffer contents or a single command to Nuke's command port.

    nukevimRun(forcedBuffer = False) : bool

    Saves the current buffer to a temporary file and instructs Nuke to source this file. In visual
    mode only the selected lines are used (for partially selected lines the complete line will be
    included). In visual mode, forceBuffer may be set to True to force execution of the complete buffer.

    Returns False if an error occured, else True.
    """

    global __nukevimTempFiles

    filetype = vim.eval('&g:filetype')
    if filetype not in ['', 'python']:
        return __nukevimError('Error: Supported filetypes: "python", None.')

    tempDir = vim.eval('g:nukevimTempDir')
    if tempDir != '':
        tempfile.tempdir = tempDir
    else:
        tempfile.tempdir = None

    (tmpHandle, tmpPath) = tempfile.mkstemp(suffix = '.tmp', prefix = 'nukevim.', text = 1)
    __nukevimTempFiles.append(tmpPath)

    try:
        vStart = vim.current.buffer.mark('<')
        if(vStart is None) or (forceBuffer):
            for line in vim.current.buffer:
                os.write(tmpHandle, '%s\n' % line)
        else:
            vEnd = vim.current.buffer.mark('>')
            for line in vim.current.buffer [vStart [0] - 1 : vEnd [0]]:
                os.write(tmpHandle, '%s\n' % line)
    finally:
        os.close(tmpHandle)

    commands = ['commandEcho -state on -lineNumbers on;']

    escapedPath = __nukevimEscape(__nukevimFixPath(tmpPath), '\\"')

    commands.append('python("execfile(\\"%s\\")");' % escapedPath)

    commands.append('commandEcho -state off -lineNumbers off;')
    commands.append('sysFile -delete "%s";' % escapedPath)

    sent = nukevimSend(commands)
    if sent != len(commands):
        return __nukevimError('%d commands out of %d sent successfully.' %(sent, len(commands)))

    return True
