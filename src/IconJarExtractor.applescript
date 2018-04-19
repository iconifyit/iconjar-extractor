--
--    Created by: Scott Lewis
--    Created on: 4/18/18
--
--    Copyright © 2018 Atomic Lotus, LLC. All Rights Reserved.
--
 
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use framework "Foundation"
use framework "AppKit"

-- 1. Accept dropped file
on open of theFiles
    set rootOutputFolder to "~/Desktop/iconjar-extractor/"
    
    try
        tell application "Finder"
            if not (my folder_exists(rootOutputFolder)) then
                set folderName to my dirname(rootOutputFolder)
                set folderPath to my parent_dir(rootOutputFolder)
                make new folder at (my to_alias("~/Desktop")) with properties {name:folderName}
            end if
        end tell
    on error eMsg number eNum
        log ("Can't create root output folder : " & eMsg & " [" & eNum & "]" as string)
    end try
    
    repeat with theFile in theFiles
        
        set theFileInfo to info for theFile
        set theFileName to name of theFileInfo
        set theFileBaseName to my basename(theFileName)
        set theFilePath to POSIX path of theFile as string
        set metaDataPath to ((POSIX path of theFile) & "META") as string
        set iconsDirPath to ((POSIX path of theFile) & "icons/") as string
        set theFileName to name of theFileInfo
        
        -- 2. Copy "icons" and "META" from dropped file to "extracted" folder
        -- com.iconjar-jar
        set theFileType to my get_file_type(theFilePath)
        if theFileType is not "com.iconjar-jar" then
            display dialog "This script only works with IconJar files. " & theFileType & " given." buttons {"Cancel"}
            exit repeat
        end if
        
        -- 3. Make a new directory for the exports
        set uuid to my short_uuid()
        set theOutputPath to rootOutputFolder & my str_replace(theFileName, ".iconjar", "") & "-" & uuid as string
        
        set theSrcFolder to theOutputPath & "/src" as string
        set theOutputFolder to theOutputPath & "/out" as string
        
        do shell script "mkdir " & theOutputPath with administrator privileges
        do shell script "mkdir " & theSrcFolder with administrator privileges
        do shell script "mkdir " & theOutputFolder with administrator privileges
        do shell script ("chmod 777 " & theOutputPath as string) with administrator privileges
        
        -- 4. Copy META to META.zip
        
        do shell script ("cp " & metaDataPath & " " & theSrcFolder & "/META.gz" as string) with administrator privileges
        do shell script ("cp -R " & iconsDirPath & " " & theSrcFolder & "/icons" as string) with administrator privileges
        do shell script ("chmod -R 777 " & theOutputPath as string) with administrator privileges
        
        -- 5. Decompress the GZIP file
        
        do shell script ("gunzip -kf " & theSrcFolder & "/META.gz" as string)
        
        -- 6. Rename META.zip folder to META.json
        
        set theMetaJsonPath to (theSrcFolder & "/META.json" as string)
        set theMetaExtractPath to (theSrcFolder & "/META" as string)
        
        do shell script ("cp " & theMetaExtractPath & " " & theMetaJsonPath as string)
        
        -- 8. Rename /icons/{icon} using tags
        -- return
        my rename_icons(theMetaJsonPath, theSrcFolder & "/icons/" as string)
        
        -- 9. Re-zip "icons" for upload
        
        -- return
        set sh_script to "cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string
        -- return sh_script
        do shell script ("cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string)
        do shell script ("mv " & theSrcFolder & "/" & theFileBaseName & ".zip " & theOutputFolder & "/" as string)
        
    end repeat
end open


-- --------------------
-- FUNCTIONS
-- --------------------

on short_uuid()
    set uuid to (do shell script "uuidgen")
    set uuid to my str_replace(uuid, "-", " ")
    set uuid to (do shell script "A=\"" & uuid & "\" ; echo \"${A##* }\";")
    return uuid
end short_uuid

on file_exists(theFile) -- (String) as Boolean
    set test to (do shell script "[ ! -f '" & theFile & "' ] || echo 1 ;")
    return (test as number) is 1
end file_exists

on folder_exists(theFile) -- (String) as Boolean
    set theFile to my expand_path(theFile)
    set test to (do shell script "[ ! -d '" & theFile & "' ] || echo 1 ;")
    return (test as number) is 1
end folder_exists

on dirname(thepath)
    if character (length of thepath) of thepath is "/" then
        set thepath to characters 1 thru ((length of thepath) - 1) of thepath as string
    end if
    return item -1 of my explode("/", thepath)
end dirname

on parent_dir(thepath)
    local ASTID
    set ASTID to AppleScript's text item delimiters
    try
        set AppleScript's text item delimiters to "/"
        set theBaseName to (text items 1 thru -3 of thepath & "") as string
        set AppleScript's text item delimiters to ASTID
        return theBaseName
    on error eMsg number eNum
        set AppleScript's text item delimiters to ASTID
        error "Can't get base name: " & eMsg number eNum
    end try
end parent_dir

on rename_icons(theMetaDataFile, theIconFolderPath)
    -- set theJsonData to read_file(theMetaDataFile as «class furl»)
    
    set theJsonData to (do shell script ("cat " & theMetaDataFile as string))
    
    tell application "JSON Helper"
        set theData to read JSON from theJsonData
    end tell
    
    set theIcons to |items| of theData
    
    set iconsDict to current application's NSDictionary's dictionaryWithDictionary:theIcons
    set theKeys to iconsDict's allKeys()
    
    set steps to count of theKeys
    
    progress_start(steps, "Processing icons ...", "Preparing to process.")
    
    set iconUpdates to {}
    set n to 1
    repeat with theKey in theKeys
        -- Update the progress detail
        progress_update(n, steps, "Processing icon ")
        repeat 1 times -- # fake loop
            set theIcon to (iconsDict's valueForKey:theKey) as record
            set theTags to tags of theIcon
            if my trim(theTags) is "" then
                exit repeat
            end if
            set theName to |name| of theIcon
            set theFile to |file| of theIcon
            set newFileName to my tags_to_slug(theTags)
            set newFileName to "test-" & newFileName as string
            log newFileName
            set from_file to theIconFolderPath & theFile as string
            set the_ext to my file_ext(from_file)
            set to_file to theIconFolderPath & newFileName & "." & the_ext as string
            set mv_script to "mv " & from_file & " " & to_file as string
            do shell script mv_script
            log mv_script
            -- (BEGIN) Update Icon
            -- set |file| of theIcon to newFileName & "." & the_ext as string
            -- copy theIcon to the end of iconUpdates
            -- set (iconsDict's valueForKey:theKey) to theIcon
            -- (END) Update Icon
        end repeat
        -- Increment the progress
        my progress_step(n)
        set n to n + 1 as number
    end repeat
    
    -- Reset the progress information
    progress_end()
    
    return iconUpdates
end rename_icons

on get_file_type(theFilePath)
    set theUTI to (current application's NSWorkspace's sharedWorkspace()'s typeOfFile:theFilePath |error|:(missing value))
    if theUTI = missing value then error theError's localizedDescription() as text
    return theUTI as text
end get_file_type

-- (BEGIN) - Progress bar
on progress_start(steps, descript, descript_add)
    set progress total steps to steps
    set progress completed steps to 0
    set progress description to descript
    set progress additional description to descript_add
end progress_start

on progress_update(n, steps, message)
    set progress additional description to message & n & " of " & steps
end progress_update

on progress_step(n)
    set progress completed steps to n
end progress_step

on progress_end()
    -- Reset the progress information
    set progress total steps to 0
    set progress completed steps to 0
    set progress description to ""
    set progress additional description to ""
end progress_end
-- (END) - Progress bar

on tags_to_slug(tags)
    return my str_to_lower(str_replace(tags, ",", "-"))
end tags_to_slug

on file_ext(file_name)
    set sh_script to "filename=\"" & file_name & "\"; " & "echo ${filename##*.}"
    return (do shell script ("filename=\"" & file_name & "\"; " & "echo ${filename##*.}"))
end file_ext

on basename(file_name)
    return (do shell script ("filename=\"" & file_name & "\"; " & "echo ${filename%.*}"))
end basename

on str_to_upper(inString)
    return (do shell script "awk '{ print toupper($0) }' <<< \"" & inString & "\"")
end str_to_upper

on str_to_lower(inString)
    return (do shell script "awk '{ print tolower($0) }' <<< \"" & inString & "\"")
end str_to_lower

on home_dir()
    set homeFolder to (path to home folder)
    return POSIX path of homeFolder
end home_dir

on to_posix(thepath)
    return ((POSIX path of my expand_path(thepath)) as string)
end to_posix

on to_alias(thepath)
    (POSIX file (my expand_path(thepath))) as alias
end to_alias

on expand_path(givenPath)
    return str_replace(givenPath, "~/", home_dir())
end expand_path

on load_script(scriptName)
    set theScript to (desktop_dir() & scriptName as string)
    return (load script theScript)
end load_script

on desktop_dir()
    return POSIX path of (path to desktop folder)
end desktop_dir

on read_file(unixPath)
    return (read unixPath)
end read_file

on trim(someText)
    -- default values (all whitespace)
    set theseCharacters to {" ", tab, ASCII character 10, return, ASCII character 0}
    
    repeat until first character of someText is not in theseCharacters
        set someText to text 2 thru -1 of someText
    end repeat
    
    repeat until last character of someText is not in theseCharacters
        set someText to text 1 thru -2 of someText
    end repeat
    
    return someText
end trim

on explode(the_delim, the_string)
    local ASTID
    set ASTID to AppleScript's text item delimiters
    set the_items to {}
    try
        set AppleScript's text item delimiters to the_delim
        -- set the_items to every text item of the_string
        set the_parts to every text item of the_string as list
        repeat with the_item in the_parts
            -- set the_items to the_items & trim(the_item) as list
            copy the_item to end of the_items
        end repeat
        set AppleScript's text item delimiters to ASTID
        return the_items as list
    on error eMsg number eNum
        set AppleScript's text item delimiters to ASTID
        error "Can't do split: " & eMsg number eNum
    end try
end explode

on implode(delimiter, pieces)
    local delimiter, pieces, ASTID
    set ASTID to AppleScript's text item delimiters
    try
        set AppleScript's text item delimiters to delimiter
        log (pieces as string)
        set the_string to (items of pieces) as string
        set AppleScript's text item delimiters to ASTID
        return the_string --> text
    on error eMsg number eNum
        set AppleScript's text item delimiters to ASTID
        error "Can't implode: " & eMsg number eNum
    end try
end implode

on str_replace(theText, oldString, newString)
    local ASTID, theText, oldString, newString, lst
    set ASTID to AppleScript's text item delimiters
    try
        considering case
            set AppleScript's text item delimiters to oldString
            set lst to every text item of theText
            set AppleScript's text item delimiters to newString
            set theText to lst as string
        end considering
        set AppleScript's text item delimiters to ASTID
        return theText
    on error eMsg number eNum
        set AppleScript's text item delimiters to ASTID
        error "Can't replaceString: " & eMsg number eNum
    end try
end str_replace
