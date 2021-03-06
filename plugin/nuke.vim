" vim.nuke -- an integration packge for vim and The Foundry's Nuke
" Copyright (C) 2016 Jesse Spielman
"
" This file is part of nuke.vim.
"
" nuke.vim is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" nuke.vim is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with nuke.vim.  If not, see <http://www.gnu.org/licenses/>.

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

call NukevimSetConfig( 'Host',             '127.0.0.1' )
call NukevimSetConfig( 'Port',             10191       )
call NukevimSetConfig( 'TempDir',          ''          )

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
command -nargs=0 NukevimBuffer  :py nukevimRun(forceBuffer = True)

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

    This function will be called automatically when leaving Vim. It will try to 
    delete all the temporary files created during the session. There is no error
    handling, if deleting a file fails, the file will be left on disk.

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

    This function will print the error message in Vim's message area, using the
    appropriate error highlighting.

    It will always return False.
    """

    vim.command('echohl ErrorMsg | echo "%s" | echohl None' % (
            __nukevimEscape(message, '\\"')))

    return False

def __nukevimEscape(string, characters):

    """Escape specified characters in a string with backslash.

    __nukevimEscape(string, characters) : str

    Works like Vim's escape() function. Every occurrence of one of the
    characters in the characters parameter inside the string will be replaced
    by '\' + character. The backslash itself has to be included as the first
    character in the characters parameter if it also should be escaped!

    Returns the resulting string.
    """

    for character in characters:
        string = string.replace(character, '\\%s' % character)

    return string

def __nukevimFilenameEscape(filename):

    """Apply Vim's fnameescape() function to a string.

    __nukevimFilenameEscape(string) : str

    This function may be used to apply Vim's fnameescape() function to the
    supplied parameter.

    Returns the escaped string.
    """

    return vim.eval('fnameescape("%s")' % __nukevimEscape(filename, '\\"'))

def __nukevimFixPath(filename):

    """Replace all backslashes in the file name with slashes on Windows
    platforms.

    __nukevimFixPath(filename) : str

    Replaces all backslashes in the file name with slashes on Windows platforms.

    Returns the resulting string.
    """

    if platform.system() == 'Windows':
        return filename.replace('\\', '/')
    else:
        return filename

def nukevimSend(instructions_path):

    """Send insructions to Nuke via a tempfile with python commands

    nukevimSend(instructions_path) : int

    This function will open a connection to a socket server running in nuke
    (as configured), and send the path to a file containing python code.  The
    corresponding server component will recieve the path and exec the contents.

    Socket exceptions will be caught and an appropriate error message will be
    displayed. After an exception, no attempt will be made to send any more
    commands from the list.

    Returns any output recieved.
    """

    host       =      vim.eval('g:nukevimHost'   )
    port       =  int(vim.eval('g:nukevimPort'   ))

    try:
        connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        connection.settimeout(None)
    except socket.error as e:
        __nukevimError('Could not initialize the socket: %s' % str(e))
        return 0

    try:
        __nukevimMsg("Trying to connect to %s:%s" % (host, port))
        connection.connect((host, port))
    except socket.error as e:
        __nukevimError('Could not connect to command port: %s' % str(e))
        return 0

    try:
        try:
            __nukevimMsg("Sending %s" % instructions_path)
            connection.send(instructions_path)

            # limit reply to 16K
            return connection.recv(16384)

        except socket.error as e:
            __nukevimError('Sending a command failed: %s' % str(e))

    finally:
        connection.shutdown(socket.SHUT_WR)
        connection.close()

def nukevimRun(forceBuffer = False):

    """Sent (partial) buffer contents to nuke via a tempory instructions file

    nukevimRun(forcedBuffer = False) : bool

    Saves the current buffer to a temporary file and instructs Nuke to source
    this file. In visual mode only the selected lines are used (for partially
    selected lines the complete line will be
    included).

    If any output is recieved, it is logged to vim's :messages queue via echom

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

    (tmpHandle, tmpPath) = tempfile.mkstemp(
            suffix='.tmp', prefix='nukevim.', text=1)

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

    escaped_path = __nukevimEscape(__nukevimFixPath(tmpPath), '\\"')

    response = nukevimSend(escaped_path)
    if response:
        # Print the results
        for line in response.split("\n"):
            __nukevimMsg(line)
        return True
    else:
        return False

