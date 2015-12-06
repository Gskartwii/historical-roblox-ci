# Valkyrie CI system
The Valkyrie CI system is a small [Lapis](http://leafo.net/lapis/) application that is invoked when the [Valkyrie Framework repository](https://github.com/ValkyrieRBXL/ValkyrieFramework) sends a push event through GitHub webhooks.

When invoked, Valkyrie CI will attempt to pull/clone the changes, compile them into a Roblox RBXM model and upload it to Roblox. Here's [a list](https://gskw.dedyn.io:444/models) of uploaded models' IDs.

## Credits
Credits to:

* Leafo for creating [Lapis](http://leafo.net/lapis/)
* CheyiLin for creating [ljlz4](https://github.com/CheyiLin/ljlz4)
* [Gregory Comer](http://gregorycomer.com/) for documenting the RBXM/L format
