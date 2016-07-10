# nuke.vim
An integration package for the Foundry's [Nuke](https://www.thefoundry.co.uk/products/nuke/).  This is my first vim plugin so go easy on me!

![Screenshot of nuke.vim](https://github.com/heavyimage/nuke.vim/blob/master/docs/screenshot.png "Screenshot of nuke.vim")
# What works now
* Syntax highlighting / a simple ftdetect plugin for .nk/.gizmo files!
* Use vim as a replacement for the builtin nuke (Nuke Studio / Hiero) script editor(s)

# Coming soon
* Improvements to vim-as-script-editor (see TODO)
* Nuke function python code completion in vim
* A terminal based node viewer
* Broaden into vfx.vim with setups for other apps?!
* Other cool ideas you send to me

# Requirements
* A copy of vim compiled with python support (check vim --version; if you don't have support, try installing an enhanced or "huge" verison of vim with more flags enabled)
* The Foundry Nuke (tested with version 10.0v2 on macOS and linux)

# Installation

* Copy plugin, doc, syntax, and ftdetect directories into your '~/.vim' directory.  If you use Pathogen and git (recommended!), instead git clone nuke.vim into your ~/.vim/bundles directory:

	```bash
	    $ mkdir ~/.vim/bundles
	    $ cd ~/.vim/bundles
	    $ git clone https://github.com/heavyimage/nuke.vim
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

    * The same code should work just fine for Nuke Studio -- for Hiero, you'll have to import the server in a slightly different way (consult the docs [Here](https://www.thefoundry.co.uk/products/hiero/developers/1.8/hieropythondevguide/setup.html "Maniuplating the hiero plugin path"))

* Startup nuke and make sure there's a message in the terminal like 'nuke.vim server listening on $HOST:$PORT'

# Now the fun part!

Startup vim, and fill the buffer with a few python snippits

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

Then, consider the chart below:

| Command | Pneuonic | Description |
| --- | --- | --- |
| <leader>sn | (s)end to (n)uke | Send the selection (or the current line if nothing is selected) to nuke |
| <leader>sb | (s)end (b)uffer | Send the entire buffer to nuke |

You should be iterating in no time!

For more information, consult doc/nukevim.txt.

# Enjoy!

