# .hammerspoon
my personal configuration, up to date status of my ~/.hammerspoon folder.

### What is it ?
[Hammerspoon](https://www.hammerspoon.org/) 
>"...tool for powerful automation of macOS. At its core, Hammerspoon is just a bridge between the operating system and a Lua scripting engine. What gives Hammerspoon its power is a set of extensions that expose specific pieces of system functionality, to the user."

If you are not familiar with Hammerspoon and its potential, before installing it, it would be helpful to at least read the [initial guide](https://www.hammerspoon.org/go/)

### Disclaimer
This repository contain my personal configuration, it is evolving and not really meant to be copied as is. It's not even made to be modular really. But if you dive deeply enough, you may be able to figure out how things work and then you can make use of whatever part you like.
I am not responsible if something goes wrong; if you use this code, it is because you know what you are doing. However, if you want to report anything or contact me for assistance, feel free to open an issue.

### Key Bindings  ...meta, super, hyper key 😃
First of all, what is the Hyper key?
The modifier keys found on modern keyboards have their origins mainly from computer keyboards of [Xerox Alto](https://it.wikipedia.org/wiki/Xerox_Alto) and [MIT space-cadet-keyboard](https://en.wikipedia.org/wiki/Space-cadet_keyboard)
Other useful information here: [Modifiers Key](https://en.wikipedia.org/wiki/Modifier_key)

So, what is the Hyper key? It is not present on modern keyboards, but it can be simulated with <kbd>Control</kbd> + <kbd>Option</kbd> + <kbd>Command</kbd> or others exotic key to ensures that the defined keyboard shortcuts do not interfere with the operating system or any other program.<br>
Some people like to map the Hyper key to the <kbd>caps lock</kbd> key, and you can do it easily with [Karabiner elements](https://karabiner-elements.pqrs.org/) or with some tricks even just with Hammerspoon itself with the help of macOS system utility `hdiutil`<br> also because Karabiner is known to be critical with system updates, perhaps also due to Apple, which likes to make radical changes to the deepest and least known parts of macOS, even without thoroughly documenting them.
Here are some useful insights to refer to:<br>
[Blog article about hidutil](https://rakhesh.com/mac/using-hidutil-to-map-macos-keyboard-keys/)<br>
[Apple tech notes about remapping key from macOS Sierra](https://developer.apple.com/library/archive/technotes/tn2450/_index.html#//apple_ref/doc/uid/DTS40017618-CH1-KEY_TABLE_USAGES)<br>
[hidutil key remapping generator for MacOS](https://hidutil-generator.netlify.app/)<br>
[Issue on the GitHub repo of the above utility explains how to remap per specific device.](https://github.com/amarsyla/hidutil-key-remapping-generator/issues/4)


However, I preferred the simple approach, Also because for me it's convenient to use the three-key modifier combination on my Logitech MX KEYS for Mac.

The init.lua file is practically the entry point for hammerspoon, and in the first lines of code you can find the global variables to define the shortcut.
```lua
Hyper = { "cmd", "alt", "ctrl" }
Shift_hyper = { "cmd", "alt", "ctrl", "shift" }
```
However, here in my config there are other shortcuts that do not involve <kbd>hyper</kbd>, but these are also specific and should not interfere with a normal system configuration; I still recommend caution, especially for those who use Karabiner or have remapped keyboard with hdiutil.

Below the description of the various modules, I added the shortcuts that activate the function, a brief description if needed and the source from where I took the code or from which I was inspired for the idea.

 ### function

|Description   |Key binding   |code   |Source reference|
|-----------|--------------|-------|----------------|
|Move and resize the active window<br>in various ways that I like |<kbd>hyper</kbd> + <kbd>arrow keys</kbd><br><kbd>hyper</kbd> + <kbd>home</kbd> / <kbd>end</kbd><br><kbd>hyper</kbd> + <kbd>PgUp</kbd> / <kbd>PgDown</kbd><br>|`win_position.lua`|The code is mine, ideas from various sources<br>Contains also some experiment with chooser|
|context menu for date, symbol, accent and emoji. |<kbd>hyper</kbd> + <kbd>V</kbd><br>|`snippet.lua`|The code is mine|
|

- <kbd>hyper</kbd> + <kbd>V</kbd> = context menu to fast insert date in many format, symbol, accent and emoji.
- <kbd>hyper</kbd> + <kbd>⇞</kbd> / <kbd>⇟</kbd> / <kbd>↑</kbd> / <kbd>↓</kbd> / arrow key = resize and move window 

### Installation

nothing special here, copy .hammerspoon in your home dir, or feel free to take what you want.

## Credit
Some of the scripts, spoons, and modules were adapted from various sources. For example:

- https://github.com/Hammerspoon/Spoons
- https://github.com/pasiaj/Translate-for-Hammerspoon
