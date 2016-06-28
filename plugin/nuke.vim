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
call NukevimSetConfig( 'ForceRefresh',     0             )
call NukevimSetConfig( 'Host',             'nomad.local' )
call NukevimSetConfig( 'Port',             50777         )
call NukevimSetConfig( 'RefreshWait',      2.0           )
call NukevimSetConfig( 'ShowLog',          1             )
call NukevimSetConfig( 'Socket',           ''            )
call NukevimSetConfig( 'SplitBelow',       &splitbelow   )
call NukevimSetConfig( 'TailCommand',      'TabTail'     )
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
command -nargs=1 NukevimCommand :py nukevimRun(userCmd     = <q-args>)
command -nargs=1 NukevimSend    :py nukevimSend([<q-args>]            )

"""
" Main stuff (most of it is Python):
"""

let g:nukevimTailAvailable = 0
if exists('g:Tail_Loaded')
    let g:nukevimTailAvailable = 1
endif

autocmd VimLeavePre * py __nukevimRemoveTempFiles()

python << EOP

import os
import platform
import socket
import tempfile
import time
import vim

# Global variables:

# If not empty, path of the log file currently used by Nuke.
__nukevimLogPath   = ''
# Contains all the temporary files created (log files, Python files).
__nukevimTempFiles = []

def __nukevimRemoveTempFiles():

    """Remove all temporary files.

    __nukevimRemoveTempFiles() : None

    This function will be called automatically when leaving Vim. It will try to delete all the
    temporary files created during the session. There is no error handling, if deleting a file
    fails, the file will be left on disk.

    If a log file is set this function will try to close it first, see __nukevimStopLogging().

    This function does not return anything.
    """

    global __nukevimLogPath, __nukevimTempFiles

    if __nukevimLogPath != '':
        __nukevimStopLogging()

    for tempFile in __nukevimTempFiles:
        if os.path.isfile(tempFile):
            try:
                os.unlink(tempFile)
            except:
                pass

def __nukevimStopLogging():

    """Tell Nuke to stop logging and close all open log files.

    __nukevimStopLogging() : bool

    If a log file is currently set, this function will send the `cmdFileOutput -closeAll` command
    to Nuke, causing all(!) open log files to be closed. The __nukevimLogPath variable will be set
    to an empty string if the log file could be closed successfully, its original value will be
    added to the __nukevimTempFiles list for clean up on exit.

    If the connection fails, an error message will be shown and the return value will be False,
    else this function returns True. If no log file has been set, this function does nothing and
    returns True.
    """

    global __nukevimLogPath, __nukevimTempFiles

    if __nukevimLogPath == '':
        return True

    if nukevimSend(['cmdFileOutput -ca;']) == 1:
        __nukevimTempFiles.append(__nukevimLogPath)
        __nukevimLogPath = ''
        return True
    else:
        return __nukevimError('Could not close the log file.')

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

def __nukevimFindLog():

    """Find the buffer and tab that contains the Nuke log.

    __nukevimFindLog() : (int, int)

    If a Nuke log file is currently set, this function will return the number of the tab page and
    the buffer number in which this log file is opened. Note: Searching will stop on first match!
    There is no convenient way to check if a window is a preview window without switching tabs, so
    this is not checked, the buffer found may be a regular window!

    Returns a tuple: (tabNumber, bufferNumber). If the log file is not set or not opened in any
    buffer, this function returns the tuple (0, 0). If there is a buffer for the log file, but it
    is not opened in any window (and thus in no tab), the return value will be (0, bufferNumber).
    """

    global __nukevimLogPath

    if __nukevimLogPath != '':
        bufferIndex  = int(vim.eval('bufnr     ("%s")' % __nukevimEscape(__nukevimLogPath, '\\"')))
        bufferExists = int(vim.eval('bufexists ( %d )' % int(bufferIndex)))
        if bufferExists:
            tabNum = int(vim.eval('tabpagenr("$")'))
            for tabIndex in range(1, tabNum + 1):
                tabBuffers = vim.eval('tabpagebuflist(%d)' % tabIndex)
                if str(bufferIndex) in tabBuffers:
                    return (tabIndex, bufferIndex)
        return (0, bufferIndex)

    return (0, 0)

def nukevimRefreshLog():

    """Update the log file in the preview window.

    nukevimRefreshLog() : bool

    This function will update the log file if it is currently opened in a preview window. If the
    window of the log file is not located in the current tab, it will switch to the window's tab.
    If the log file's window is a regular window, no attempt to refresh it will be made (the tab
    will be switched, though). Does nothing if no log file is currently set.

    If no log file is set, returns True. Same if a log file is set and opened in a preview window
    (or a regular window). If a log file is set, but not opened in any window, returns False (and
    prints an error message).
    """

    global __nukevimLogPath

    if __nukevimLogPath != '':

        (tabIndex, bufferIndex) = __nukevimFindLog()

        if not tabIndex:
            return __nukevimError('No log file window found.')
        else:
            vim.command('tabnext %d' % tabIndex)
            winIndex = int(vim.eval('bufwinnr(%d)' % bufferIndex))
            if winIndex > 0 and int(vim.eval('getwinvar(%d, "&previewwindow")' % winIndex)):
                vim.command('call tail#Refresh()')

    return True

def nukevimOpenLog():

    """Open the log file using the Tail Bundle plugin.

    nukevimOpenLog() : bool

    This function will open the currently used log file using the configured Tail Bundle command,
    unless this is disabled. The options g:nukevimShowLog, g:nukevimTailCommand and g:nukevimSplitBelow
    may be used to change the behaviour. If no log file is set, or the file is already opened in a
    window, this function does nothing. If g:nukevimTailCommand is not 'TabTail', any preview window
    currently opened will be closed.

    Returns False in case of an error, True in all other cases.
    """

    global __nukevimLogPath

    (tabIndex, bufferIndex) = __nukevimFindLog ()

    if __nukevimLogPath != '' and tabIndex == 0:

        splitBelowGlobal  = int(vim.eval('&splitbelow'       ))
        splitBelowNukevim = int(vim.eval('g:nukevimSplitBelow' ))
        tailCommand       =      vim.eval('g:nukevimTailCommand')

        if tailCommand not in('Tail', 'STail', 'TabTail'):
            return __nukevimError('Invalid value for g:nukevimTailCommand.')

        success = False

        try:
            if tailCommand != 'TabTail':
                vim.command('pclose')
            if splitBelowNukevim:
                vim.command('set splitbelow')
            else:
                vim.command('set nosplitbelow')
            vim.command('%s %s' % (tailCommand, __nukevimFilenameEscape(__nukevimLogPath)))
            if tailCommand != 'TabTail':
                vim.command('wincmd p')
            success = True
        finally:
            if splitBelowGlobal:
                vim.command('set splitbelow')
            else:
                vim.command('set nosplitbelow')

        return success

    return True

def nukevimResetLog():

    """(Re)set Nuke's log file.

    nukevimResetLog() : bool

    This function will create a temporary file and instruct Nuke to use it as its log file. If a
    log file is already set, the command to close all (!) log files will be sent to Nuke first,
    then the new file is set. The log file will be opened in Vim if enabled, see nukevimOpenLog()
    for details. If g:nukevimShowLog is not enabled (or the Tail Bundle plugin is not available), no
    new log file will be created (if a log file should be set, it will still be closed, though).

    Returns True on success, False in case of failure.
    """

    global __nukevimLogPath

    if __nukevimLogPath != '':
        if not __nukevimStopLogging():
            return False

    tailAvailable = int(vim.eval('g:nukevimTailAvailable'))
    showLog       = int(vim.eval('g:nukevimShowLog'      ))

    if tailAvailable and showLog:

        tempDir = vim.eval('g:nukevimTempDir')
        if tempDir != '':
            tempfile.tempdir = tempDir
        else:
            tempfile.tempdir = None

        (logHandle, logPath) = tempfile.mkstemp(suffix = '.log', prefix = 'nukevim.', text = 1)
        __nukevimLogPath = vim.eval('expand("%s")' % __nukevimEscape(logPath, '\\"'))

        escapedLogPath = __nukevimEscape(__nukevimFixPath(__nukevimLogPath), '\\"')
        if nukevimSend(['cmdFileOutput -o "%s";' % escapedLogPath]) != 1:
            return False

        return nukevimOpenLog()

    return True

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

def nukevimRun(forceBuffer = False, userCmd = None):

    """Sent (partial) buffer contents or a single command to Nuke's command port.

    nukevimRun(forcedBuffer = False, userCmd = None) : bool

    If userCmd is not specified, saves the current buffer to a temporary file and instructs Nuke to
    source this file. In visual mode only the selected lines are used (for partially selected lines
    the complete line will be included). In visual mode, forceBuffer may be set to True to force
    execution of the complete buffer.

    If userCmd is specified, this command will be written to the file executed by Nuke, and the
    buffer content will be ignored.

    If Nuke's log is not yet set, it will be set and opened (if configured), depending on the
    'g:nukevimShowLog' setting. See nukevimResetLog() for details. If 'g:nukevimForceRefresh' is set,
    nukevimRefreshLog() will be called after waiting for 'g:nukevimRefreshWait' seconds after all
    commands have been sent to Nuke. Note that if a log file has been set and you close the log
    window, it will not be opened automatically, you may use nukevimOpenLog() to open it again.

    Returns False if an error occured, else True.
    """

    global __nukevimLogPath, __nukevimTempFiles

    filetype = vim.eval('&g:filetype')
    if filetype not in ['', 'python']:
        return __nukevimError('Error: Supported filetypes: "python", None.')

    if __nukevimLogPath == '':
        if not nukevimResetLog():
            return False

    tempDir = vim.eval('g:nukevimTempDir')
    if tempDir != '':
        tempfile.tempdir = tempDir
    else:
        tempfile.tempdir = None

    (tmpHandle, tmpPath) = tempfile.mkstemp(suffix = '.tmp', prefix = 'nukevim.', text = 1)
    __nukevimTempFiles.append(tmpPath)

    try:
        if userCmd:
            os.write(tmpHandle, '%s\n' % userCmd)
        else:
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

    refresh = int  (vim.eval('g:nukevimForceRefresh'))
    wait    = float(vim.eval('g:nukevimRefreshWait' ))
    if __nukevimLogPath != '' and refresh:
        time.sleep(wait)
        return nukevimRefreshLog()

    return True
