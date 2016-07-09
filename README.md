# nuke.vim
An integration package for the Foundry's [Nuke](https://www.thefoundry.co.uk/products/nuke/).  This is my first vim plugin so go easy on me!

![Screenshot of nuke.vim](https://github.com/heavyimage/nuke.vim/blob/master/docs/screenshot.png "Screenshot of nuke.vim")

# What works now
* Syntax highlighting / a simple ftdetect plugin for .nk/.gizmo files!
* Use vim as a replacement for the builtin nuke script editor

# Coming soon
* Improvements to vim-as-script-editor (see TODO)
* Nuke function python code completion in vim
* A terminal based node viewer
* Broaden into vfx.vim with setups for other apps?!
* Other cool ideas you send to me

# Requirements
* A copy of vim compiled with python support (check vim --version; if you don't have support, try installing an enhanced or "huge" verison of vim with more flags enabled)
* The Pathogen plugin
* A copy of git
* The Foundry Nuke (tested with version 10.0v2 on macOS / linux)

# Installation

* Copy plugin, doc, syntax, and ftdetect directories into your '~/.vim' directory
    * If you use Pathogen, instead git clone nuke.vim into your ~/.vim/bundles directory:

	```bash
	    $ mkdir ~/.vim/bundles
	    $ cd ~/.vim/bundles
	    $ git clone https://github.com/heavyimage/nuke.vim
	```

* Modify your ~/.vimrc to set up some global variables for nuke.vim.

    ```vimscript
	let 'g:nukevimHost'     = '<hostname>'  # The hostname (if localhost doesn't work, try the output of `hostname`)
	let 'g:nukevimPort'     = 50777         # The port for the connections
	let 'g:nukevimTempDir'  = ''            # If you want to specify a tempdir for the instruction files
	let 'g:nukevimTimeout'  = 5.0           # A timeout in seconds for the socket connection
    ```

* Source the nukevim_server.py file distributed with nuke.vim (in the nuke/ directory) in your menu.py
    * via a symlink (prefered, in case there are updates to nuke.vim's server component pushed to github)

        ```bash
            $ mkdir ~/.nuke
            $ ln ~/.vim/bundles/nuke.vim/nuke/nukevim_server.py ~/.nuke/nukevim_server.py
            $ cat "#start nukevim server\n\nimport nukevim_server\n\nnukevim_server.start()" >> ~/.nuke/menu.py
        ```

    * or as a copy:

        ```bash
            $ mkdir ~/.nuke
            $ cp ~/.vim/bundles/nuke.vim/nuke/nukevim_server.py ~/.nuke/
            $ cat "#start nukevim server\n\nimport nukevim_server\n\nnukevim_server.start()" >> ~/.nuke/menu.py
        ```

* Startup nuke and make sure there's a message in the terminal like 'nukevim server listening on $HOST:$PORT'
* Startup vim, and fill the buffer with a few python snippits

    ```Python
    nuke.createNode("Blur")

    10+50

    import math
    for i in range(360):
        x = int(math.cos(math.radians(i))) * 500
        y = int(math.sin(math.radians(i))) * 500
        d = nuke.createNode("Dot")
        d.setXYpos(x, y)
    ```

* use <leader>sn (pneumonic: (s)end to (n)uke) to send the selection (or the buffer if nothing is selected) to nuke
* use <leader>sb (pneumonic: (s)send (b)uffer to nuke) to force transmission of whole buffer
* Enjoy!

