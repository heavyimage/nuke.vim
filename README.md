# nuke.vim
An integration package for the Foundry's [Nuke](https://www.thefoundry.co.uk/products/nuke/).  This is my first vim plugin so go easy on me!

# What works now
* Syntax highlighting / a simple ftdetect plugin for .nk/.gizmo files!
![Screenshot 1 of nuke.vim](https://github.com/heavyimage/nuke.vim/blob/master/doc/syntax.png "Screenshot of syntax hilighting")
* Use vim as a replacement for the builtin nuke (Nuke Studio / Hiero) script editor(s)
![Screenshot 2 of nuke.vim](https://github.com/heavyimage/nuke.vim/blob/master/doc/scriptediting.png "Screenshot of using vim as a replacement for the script editor")

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

* Copy plugin, doc, syntax, and ftdetect directories into your '~/.vim' directory.  If you use Pathogen and git (recommended!), instead clone nuke.vim into your ~/.vim/bundles directory:

	```bash
	    $ mkdir ~/.vim/bundles
	    $ cd ~/.vim/bundles
	    $ git clone https://github.com/heavyimage/nuke.vim
	```

* Source the server code distributed with nuke.vim (see: nuke/nukevim_server.py) in your menu.py either

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

    * The same code should work just fine for Nuke Studio -- for Hiero, you'll have to import the server in a slightly different way (consult the docs [here](https://www.thefoundry.co.uk/products/hiero/developers/1.8/hieropythondevguide/setup.html "Maniupulating the hiero plugin path").)

* Startup nuke and make sure there's a message at startup that looks something like this:
    ```bash
        nuke.vim server: listening on 127.0.0.1:10191
    ```

# Now the fun part!

Startup vim, and fill the buffer with a few python snippits

```python
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
| \<leader\>sn | (s)end to (n)uke | Send the selection (or the current line if nothing is selected) to nuke |
| \<leader\>sb | (s)end (b)uffer | Send the entire buffer to nuke |

You should be iterating in no time!  For more information, consult doc/nukevim.txt or me, via e-mail.

# Enjoy!

