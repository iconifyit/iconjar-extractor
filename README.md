# IconJarExtractor

This AppleScript droplet extracts icons from an IconJar archive and renames the icons using the tags set in IconJar.

## Usage

1. Download this script to your Mac computer and extract the ZIP file. 
2. Double-click the file named `JSON Helper.zip` and copy the extracted file to your `Applications` folder.
3. Drop 1 or more IconJar files onto the IconJarExtractor droplet.
4. The script will create a folder on your desktop named `iconjar-extractor`
5. The icons will be extracted from your IconJar file and renamed using the tags you have specified in IconJar. If no tags have been specified, the name of the icons will be used. If no name has been specified, the script will error out.
6. The renamed icons will be saved in a ZIP file in `~/Desktop/icon-extractor/{name}-{uuid}/out`

## What is this for?

Icon marketplaces like Iconfinder can accept ZIP uploads and will use the names of your icons to automatically tag the icons. This script allows you to extract the icons from your IconJar files, rename them, and quickly upload them to Iconfinder without having to spend time manually re-tagging the icons.

## Reporting a Bug

Please report any issues to https://github.com/iconifyit/iconjar-exporter-appletscript/issues or via email at scott_at_atomic_lotus_dot_net.

When reporting a bug, please include as much detail as possible including:

- The year and model of your Mac computer
- The version of MacOS running on your computer
- The IconJar file you're trying to extract would also be very helpful

## Support

I am happy to provide limited support at no charge. I am also available for hire for custom scripts and more complex support issues.

## Credits

IconJarExtractor would not be possible without the fantastic JSON AppleScript utility by [MouseDown.net](http://www.mousedown.net/mouseware/JSONHelper.html), who has graciously donated a free copy of the tool to this project. Please visit their page and donate. 

## Donations

Donations help open source developers continue to create free resources. You can donate to this project at https://paypal.me/iconify. 25% of all donations to this script will be contributed to MouseDown.net

## Change Log
2018-04-25 : Fixed a bug related to file names with spaces or commas (IconJar or icon file names) causing the script to break

2018-04-25 : Added a dialog when the script finishes indicating the file location as well as a button to open the folder where the ZIP file containging the extracted icons is located

## Known Issues
- There are no known issues at this time. See **Reporting a Bug** above for instructions for reporting issues