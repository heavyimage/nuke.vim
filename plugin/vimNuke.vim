"""
" Coypright 2012 by sydh <sydhds _@ _ gmail _dot_ com> - <http://sydh.toile-libre.org>
"
" This program is free software: you can redistribute it and/or modify it under
" the terms of the GNU General Public License as published by the Free Software
" Foundation, either version 3 of the License, or (at your option) any later
" version.
"
" This program is distributed in the hope that it will be useful, but WITHOUT
" ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
" FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
" details.
"
" You should have received a copy of the GNU General Public License along with
" this program. If not, see <http://www.gnu.org/licenses/>.
"
" VimNuke 0.1 - Execute buffer contents as Python scripts in The Foundry Nuke
"
" Help is available in doc/vimNuke.txt or from within Vim with :help vimNuke. See
" the help file or the end of this file for license information.
"
" Note : forked from vimya plugin by Stefan Goebel
"""

"""
" manual test : source __PATH__/vimNuke.vim - py sendBufferToNuke()
"""

if exists('g:loadedVimNuke') || &cp || ! has('python')
    finish
endif
let g:loadedVimNuke = '0.2'

if ! exists('g:vimNukePort')
    let g:vimNukePort = 50007
endif

if ! exists('g:vimNukeHost')
    let g:vimNukeHost = '127.0.0.1'
endif

if ! exists('g:vimNukeShowLog')
    let g:vimNukeShowLog = 0
endif

let g:vimNukeUseTail = 0

"""
" Mappings:
"""

if ! hasmapto('sendBufferToNuke')
    nnoremap <leader>sn :py sendBufferToNuke()<cr>
    vnoremap <leader>sn :py sendBufferToNuke()<cr>
    nnoremap <leader>sN :py sendBufferToNuke(True)<cr>
    vnoremap <leader>sN :py sendBufferToNuke(True)<cr>
endif

python << EOP

from __future__ import with_statement
import os
import socket
import tempfile
import vim

logPath = ''
setLog = 0
tempFiles = []

# errorMsg (message = <string>):
#
# Print the error message given by <string> with the appropriate highlighting.
# Returns always False.

def __vimNukeErrorMsg(message):
    vim.command ('echohl ErrorMsg')
    vim.command ("echo \"%s\"" % message )
    vim.command ('echohl None')
    return False

# sendBufferToNuke():
#
# Saves the buffer (or a part of it) to a temporary file and instructs Nuke to
# source this file. In visual mode only the selected lines are used, else the
# complete buffer. In visual mode, forceBuffer may be set to True to force
# executing the complete buffer. If selection starts (or ends) in the middle of
# a line, the complete line is included! Returns False if an error occured,
# else True.

def sendBufferToNuke(forceBuffer=False):

    global logPath, setLog, tempFiles

    type        = vim.eval ('&g:ft')
    host        = vim.eval ('g:vimNukeHost')
    port        = int (vim.eval ('g:vimNukePort'))
    tail        = int (vim.eval ('g:vimNukeUseTail'))
    showLog     = int (vim.eval ('g:vimNukeShowLog'))

    if type != '' and type != 'python' and type != 'mel':
        return __vimyaErrorMsg (
                "Error: Supported filetypes: 'python', 'mel', None.")

    tmpDirPath = tempfile.mkdtemp(prefix='vimNuke') 
    tmpPath = os.path.join(tmpDirPath, 'vimNukeBuffer.py')  

    with open(tmpPath, 'w') as tf:
        
        vStart = vim.current.buffer.mark ('<')
        if (vStart is None) or (forceBuffer):
            for line in vim.current.buffer:
                tf.write(line+'\n')
        else:
            vEnd = vim.current.buffer.mark ('>')
            for line in vim.current.buffer [vStart [0] - 1 : vEnd [0]]:
                tf.write(line+'\n')
    
    connection = None
    for res in socket.getaddrinfo(host, port, socket.AF_UNSPEC, socket.SOCK_STREAM, 0, socket.AI_PASSIVE):

        af, socktype, proto, canonname, sa = res

        try:
            connection = socket.socket(af, socktype, proto)
        except socket.error, msg:
            connection = None
            continue

        try:
            connection.connect(sa)
        except socket.error, msg:
            connection.close()
            connection = None
            continue
        break

    if connection is None:
        return __vimNukeErrorMsg('Could not open socket: %s' % msg)

    try:
        __vimNukeErrorMsg('send file: %s' % tmpPath)
        connection.sendall('%s' % tmpPath.replace('\\', '/'))
    except socket.error, msg:
        return __vimNukeErrorMsg('Could not send the commands to Nuke: %s' % msg)

    connection.close()

    return True

EOP

" vim: set et si nofoldenable ft=python sts=4 sw=4 tw=79 ts=4 fenc=utf8 :

