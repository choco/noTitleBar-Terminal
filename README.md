「 noTitleBar Terminal.app 」
=================================

Simple SIMBL plugin that removes the Titlebar (and Toolbar) from Terminal.app.


![Screenshot 1](/screen1.png?raw=true)

Why and how
-----------

I've always envied Linux for the great window managers that the community
produces. Some nice tools to mimic that behaviour are finally surfacing on OS X
like [Hammerspoon][1] and [Kwm][2]. Many setups you see around use iTerm without
the title bar, and since I thought it was pretty cool I decided to add the same
option in Terminal.app
The basic change is removing the NSTitledWindowMask during the window creation,
the other hooked functions are needed to keep all Terminal features working.
Now it also supports padding and active tab color personalization!
The background color of the padding area is taken from the current tab
background color, to have the best integration possible.


![Screenshot 2](/screen2.png?raw=true)

Download
--------

An already compiled bundle is available:

[https://github.com/cHoco/noTitleBar-Terminal/releases]
(https://github.com/cHoco/noTitleBar-Terminal/releases)

Development
-----------

Download the development repository using Git:

    git clone --recursive git://github.com/cHoco/noTitleBar-Terminal.git

Run `make` to compile the plugin, and `make install` to install it into your
home directory's SIMBL plugins folder.

[1]: http://www.hammerspoon.org
[2]: https://github.com/koekeishiya/kwm
