RoyalTSX_Public
===============
This repository contains the public source code of Royal TSX.

### Build Requirements
* Xcode 4.6.x (Xcode 5.x is not yet supported)
* Xamarin Studio 4.0.x
* Mono 3.2.3
* Monobjc 5.0.2165.0

### Repository Structure
* __/Managed__: This folder contains managed (C#) source code
* __/Native__: This folder contains native (Objective-C/C/C++) source code
 
### How to build a Connection Plugin
* Open the native Xcode project for the desired Plugin and build it.
* Each Plugin's Xcode project contains a 'Run Script' build phase that copies the resulting .framework into the Plugin's managed source tree.
* After building the native part, open RoyalTSX_Public.sln which contains all the managed stuff with Xamarin Studio.
* Modify (or remove) the codesigning part of Managed/ConnectionPlugins/Scripts/AfterBuildScript.sh to match your code signing identity.
* Build the Plugin's managed project.
* Each Plugin's managed project contains an 'After Build Script' that strips the resulting package down to the minimum required components and copies it to Royal TSX' Plugins directory (overwriting any previously installed Plugin).
* Restart Royal TSX to reload all Plugins.
