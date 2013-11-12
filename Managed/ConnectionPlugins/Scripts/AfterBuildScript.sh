#!/bin/bash

# Working Directory must be Project Directory
# var 1: Debug or Release
# var 2: Project Name

PROJECT_DIR=$(pwd)
INPUT_INFO_DIR="PluginInfo"
PLUGIN_ID=$(grep '<ID' ${INPUT_INFO_DIR}/PluginInfo.xml | cut -f2 -d">"|cut -f1 -d"<")
OUTPUT_DIR="bin/${1}/${2}.app"
OUTPUT_DIR_PLUGIN="bin/${1}/${PLUGIN_ID}.plugin"
INPUT_FRAMEWORK_DIR="Frameworks/"
OUTPUT_INFO_DIR="${OUTPUT_DIR}/PluginInfo"
OUTPUT_RESOURCES_DIR="${OUTPUT_DIR}/Contents/Resources"
OUTPUT_FRAMEWORK_DIR="${OUTPUT_DIR}/Contents/Frameworks"
REMOJO_PLUGINS_DIR="$HOME/Library/Application Support/Royal TSX/Plugins/Installed"

# delete the PluginInfo directory
rm -rf "$OUTPUT_INFO_DIR"

#copy the PluginInfo directory to the output directory
#cp -R "$INPUT_INFO_DIR" "$OUTPUT_INFO_DIR"
rsync -r --exclude=.svn "$INPUT_INFO_DIR"/ "$OUTPUT_INFO_DIR"

# check if the frameworks directory exists in bundle
if [ -d "$OUTPUT_FRAMEWORK_DIR" ]
then
	# delete the plugins directory if it exists
	rm -rf "${OUTPUT_FRAMEWORK_DIR}"
fi

# create the frameworks directory
mkdir "$OUTPUT_FRAMEWORK_DIR"

# copy the frameworks dir contents
cp -fR "$INPUT_FRAMEWORK_DIR" "$OUTPUT_FRAMEWORK_DIR"

#clean up resources dir
cd "${OUTPUT_RESOURCES_DIR}"

if [ "${1}" != "Debug" ]
then
	rm -f *.mdb
	rm -f *.config
	rm -f System.IO.*
	rm -f System.Runtime.*
	rm -f System.Threading.*
	rm -f Newtonsoft.*
	rm -f Fleck.*
	rm -f CsQuery.*
	rm -f DataTableGridViewFramework.*
	rm -f BFColorPickerPopoverFramework.*
	rm -f Monobjc.*
	rm -f RoyalDocument.*
	rm -f RoyalLogging.*
	rm -f RoyalUtils.*
	rm -f remojoApi.*
	rm -f RoyalTSXNativeApi.*
	rm -f RoyalBrowserExtensions.*
fi

cd "${PROJECT_DIR}"

# remove the .plugin bundle
rm -rf "$OUTPUT_DIR_PLUGIN"

# rename the .app bundle to .plugin
mv "$OUTPUT_DIR" "$OUTPUT_DIR_PLUGIN"

codesign --force --sign "Developer ID Application: Felix Deimel" $OUTPUT_DIR_PLUGIN

rm -rf "${REMOJO_PLUGINS_DIR}/${PLUGIN_ID}.plugin"
cp -fR "$OUTPUT_DIR_PLUGIN" "${REMOJO_PLUGINS_DIR}/${PLUGIN_ID}.plugin"