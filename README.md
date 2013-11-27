RoyalTSX_Public
===============
This repository contains the public source code of Royal TSX.

### Build Requirements
* [Xcode 4.6.x](https://developer.apple.com/downloads) (Xcode 5.x is currently incompatible with Monobjc)
* [Xamarin Studio 4.x](http://xamarin.com/studio)
* [Mono MDK 3.2.x](http://www.go-mono.com/mono-downloads/download.html)
* [Monobjc 5.0.2165.0](http://monobjc.net/downloads.html)

### Repository Structure
* __/Managed__: This folder contains managed (C#) source code
* __/Native__: This folder contains native (Objective-C/C/C++) source code
* __/Toolbox__: This folder contains several scripts and other tools that can be used to extend/interface with Royal TSX
 
### How to build a Connection Plugin
* Open the native Xcode project for the desired Plugin and build it.
* Each Plugin's Xcode project contains a 'Run Script' build phase that copies the resulting .framework into the Plugin's managed source tree.
* After building the native part, open RoyalTSX_Public.sln which contains all the managed stuff with Xamarin Studio.
* Modify (or remove) the codesigning part of Managed/ConnectionPlugins/Scripts/AfterBuildScript.sh to match your code signing identity.
* Build the Plugin's managed project.
* Each Plugin's managed project contains an 'After Build Script' that strips the resulting package down to the minimum required components and copies it to Royal TSX' Plugins directory (overwriting any previously installed Plugin).
* Restart Royal TSX to reload all Plugins.
