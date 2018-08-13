Royal TSX V1 Public Source Code
===============
This repository contains the public source code of Royal TSX.
The information and code (except for the Toolbox) in this repository is for Royal TSX V1. For Royal TSX V2, please head over to [this repository](https://github.com/lemonmojo/RoyalTSX_V2_Public) and for Royal TSX V3 check out [this repository](https://github.com/lemonmojo/RoyalTSX_V3_Public).

### Build Requirements
* [Xcode 4.6.x](https://developer.apple.com/downloads) (Xcode 5.x is currently incompatible with Monobjc)
* [Xamarin Studio 4.x](http://xamarin.com/studio)
* [Mono MDK 3.2.x](http://www.go-mono.com/mono-downloads/download.html)
* [Monobjc 5.0.2165.0](http://monobjc.net/downloads.html)

### Repository Structure
* __/Managed__: This folder contains managed (C#) source code
* __/Native__: This folder contains native (Objective-C/C/C++) source code
* __/Toolbox__: This folder contains several scripts and other tools that can interface with Royal TSX
 
### How to build a Connection Plugin
* Open the native Xcode project for the desired Plugin and build it.
* Each Plugin's Xcode project contains a 'Run Script' build phase that copies the resulting .framework into the Plugin's managed source tree.
* After building the native part, open RoyalTSX_Public.sln which contains all the managed stuff with Xamarin Studio.
* Modify (or remove) the codesigning part of Managed/ConnectionPlugins/Scripts/AfterBuildScript.sh to match your code signing identity.
* Build the Plugin's managed project.
* Each Plugin's managed project contains an 'After Build Script' that strips the resulting package down to the minimum required components and copies it to Royal TSX' Plugins directory (overwriting any previously installed Plugin).
* Restart Royal TSX to reload all Plugins.

### Toolbox
* Content that was previously included in this repository has moved to our new [toolbox repo](https://github.com/royalapplications/toolbox).