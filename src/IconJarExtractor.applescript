--
--    Created by: Scott Lewis
--    Created on: 4/18/18
--
--    Copyright © 2018 Atomic Lotus, LLC. All Rights Reserved.
--

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use framework "Foundation"

property runCount : 0
property rootOutputFolder : "~/Desktop/iconjar-extractor/"
property logging : true
property debug : true
property ini_file : "~/Desktop/iconjarextractor-config.ini"
property has_ini_password : false

property myPassword : ""
property _HERE_ : ""

-- [1] -- Accept dropped file or run on double-click

-- drop some files on me
on open of theFiles
    my main(theFiles)
end open

-- Run by double-clicking the desktop icon
on run
    set theFiles to {} & (choose file)
    my main(theFiles)
end run

-- --------------------
-- FUNCTIONS
-- --------------------

-- @param {list} theFiles  A list of file aliases
-- @returns void
on main(theFiles)
    
    set _HERE_ to parent_dir(path to me as string) & "/" as string
    
    if file_exists(to_posix("~/Desktop/password.txt" as string)) then
        set pass_file to to_posix("~/Desktop/password.txt" as string)
        log "cat " & pass_file as string
        set myPassword to my cat(pass_file)
    end if
    
    my load_config()
    
    set uuid to my short_uuid()
    set runCount to runCount + 1
    
    try
        tell application "Finder"
            my make_folder(rootOutputFolder)
            set dateString to do shell script ("date '+%Y-%m-%d'") password myPassword with administrator privileges
            set theJobFolder to my make_folder(my increment_folder(rootOutputFolder & dateString as string))
        end tell
    on error eMsg number eNum
        logger("Can't create root output folder : " & eMsg & " [" & eNum & "]" as string)
        display dialog "Can't create root output folder : " & eMsg & " [" & eNum & "]" as string buttons {"Cancel"} default button 1
    end try
    
    set theLogFile to theJobFolder & "/iconjar-extractor.log" as string
    
    logger("-------------------- ALLONS Y! --------------------")
    
    repeat with theFile in theFiles
        
        try
            
            set theFilePath to POSIX path of theFile as string
            set theFileInfo to info for theFile
            set theFileName to name of theFileInfo
            set theFileBaseName to my strip_ext(theFileName)
            set theFileFolder to my dirname(theFilePath)
            
            set metaDataPath to ((POSIX path of theFile) & "META") as string
            set iconsDirPath to ((POSIX path of theFile) & "icons/") as string
            
            logger("File Name : " & theFileName as string)
            logger("File Base Name : " & theFileBaseName as string)
            logger("Meta Data Path : " & metaDataPath as string)
            logger("Icons Dir Path : " & iconsDirPath as string)
            logger("File Folder Path : " & theFileFolder as string)
            
            -- [2] -- Copy "icons" and "META" from dropped file to "extracted" folder
            
            set theFileType to my get_file_type(theFilePath)
            if theFileType is not "com.iconjar-jar" then
                logger("This script only works with IconJar files. " & theFileType & " given.")
                display dialog "This script only works with IconJar files. " & theFileType & " given." buttons {"Cancel"}
                exit repeat
            end if
            
            -- [3] -- Make sure the file path has no commas or spaces which can cause trouble
            
            set theFileSlug to my strip_ext(theFileName)
            set theSpaceTest to safe_file_path(theFileName)
            
            if theSpaceTest is not equal to theFileName then
                logger(theSpaceTest & " contains spaces" as string)
                
                set newFileName to str_replace(theFileName, " ", "-")
                set newFileName to str_replace(newFileName, ",", "-")
                set theFileSlug to my strip_ext(newFileName)
                
                set theOutputPath to my make_folder(theJobFolder & "/" & theFileSlug as string)
                set theSrcFolder to theOutputPath -- my make_folder(theJobFolder & "/" & theFileSlug & "/src" as string)
                
                set newFilePath to theSrcFolder & "/" & newFileName as string
                set tmpFilePath to theFilePath
                
                logger("New File Name : " & newFileName as string)
                logger("New File Path & " & newFilePath as string)
                logger("Temp File Path : " & tmpFilePath as string)
                
                if last character of tmpFilePath is "/" then
                    set tmpFilePath to characters 1 thru -2 of tmpFilePath as string
                end if
                set tmpFilePath to quoted form of tmpFilePath
                
                if not my file_exists(newFilePath) then
                    logger("Doing shell script : " & "cp -R " & tmpFilePath & " " & newFilePath as string)
                    do shell script ("cp -R " & tmpFilePath & " " & newFilePath as string)
                end if
                set theFile to to_alias(newFilePath)
                
                set theFileInfo to info for theFile
                set theFileName to name of theFileInfo
                set theFileBaseName to my strip_ext(theFileName)
                set theFilePath to POSIX path of theFile as string
                set metaDataPath to ((POSIX path of theFile) & "META") as string
                set iconsDirPath to ((POSIX path of theFile) & "icons/") as string
                set theFileName to name of theFileInfo
                set theFileFolder to my dirname(theFilePath)
                
                logger("Updated File Name : " & theFileName as string)
                logger("Updated File Base Name : " & theFileBaseName as string)
                logger("Updated Meta Data Path : " & metaDataPath as string)
                logger("Updated Icons Dir Path : " & iconsDirPath as string)
                logger("Updated File Folder Path : " & theFileFolder as string)
                
            end if
            
            -- [4] -- Make a new directory for the exports
            
            set theFileSlug to my strip_ext(theFileName)
            set theOutputPath to my make_folder(theJobFolder & "/" & theFileSlug as string)
            set theSrcFolder to theOutputPath -- my make_folder(theJobFolder & "/" & theFileSlug & "/src" as string)
            set theOutputFolder to my make_folder(theJobFolder & "/out" as string)
            
            logger("Output Path : " & theOutputPath)
            
            logger("Do Shell Script : " & "chmod 777 " & theJobFolder as string)
            do shell script ("chmod 777 " & theJobFolder as string) password myPassword with administrator privileges
            
            -- [5] -- Copy META to META.zip
            
            logger("Do Shell Script : " & ("cp " & metaDataPath & " " & theSrcFolder & "/META.gz" as string))
            do shell script ("cp " & metaDataPath & " " & theSrcFolder & "/META.gz" as string) password myPassword with administrator privileges
            
            logger("Do Shell Script : " & ("cp -R " & iconsDirPath & " " & theSrcFolder & "/icons" as string))
            do shell script ("cp -R " & iconsDirPath & " " & theSrcFolder & "/icons" as string) password myPassword with administrator privileges
            
            logger("Do Shell Script : " & ("chmod -R 777 " & theJobFolder as string))
            do shell script ("chmod -R 777 " & theJobFolder as string) password myPassword with administrator privileges
            
            -- [6] -- Decompress the GZIP file
            
            logger("Do Shell Script : " & ("gunzip -kf " & theSrcFolder & "/META.gz" as string))
            do shell script ("gunzip -kf " & theSrcFolder & "/META.gz" as string)
            
            -- [7] -- Rename META.zip folder to META.json
            
            set theMetaJsonPath to (theSrcFolder & "/META.json" as string)
            set theMetaExtractPath to (theSrcFolder & "/META" as string)
            
            logger("Meta JSON Path : " & theMetaJsonPath)
            logger("Meta Extract Path : " & theMetaExtractPath)
            
            logger("Do Shell Script : " & ("cp " & theMetaExtractPath & " " & theMetaJsonPath as string))
            do shell script ("cp " & theMetaExtractPath & " " & theMetaJsonPath as string)
            
            -- [8] -- Rename /icons/{icon} using tags

            logger("Start renaming icons ...")
            my rename_icons(theMetaJsonPath, theSrcFolder & "/icons/" as string)
            
            -- [9] -- Re-zip "icons" for upload
            
            logger("cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string)
            logger("cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string)
            logger("mv " & theSrcFolder & "/" & theFileBaseName & ".zip " & theOutputFolder & "/" as string)
            
            set sh_script to "cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string
            
            logger("Do Shell Script : " & sh_script as string)
            do shell script ("cd " & theSrcFolder & "; zip -r " & theFileBaseName & ".zip " & "icons" as string)
            
            logger("Do Shell Script : " & ("mv " & theSrcFolder & "/" & theFileBaseName & ".zip " & theOutputFolder & "/" as string) as string)
            do shell script ("mv " & theSrcFolder & "/" & theFileBaseName & ".zip " & theOutputFolder & "/" as string)
                        
        on error eMsg number eNum
            logger(("[ERROR " & eNum & "] " & eMsg as string))
            display dialog ("[ERROR " & eNum & "] " & eMsg as string) buttons {"OK"}
        end try
    end repeat
    
    logger("Your icons have been renamed and moved to `" & theOutputFolder & "/" & theFileBaseName & ".zip`" as string)
    if file_exists(ini_file) and has_ini_password then
        set theButtonReturned to button returned of (display dialog ¬
            ("Fin! Your icons have been renamed and are ready for upload to your favorite icon market." as string) ¬
                buttons {"Ok", "Secure Delete INI"} default button 2)
        if theButtonReturned is equal to "Secure Delete INI" then
            do shell script ("rm -Pv " & ini_file as string) password myPassword with administrator privileges
            set has_ini_password to false
        end if
    else
        display dialog ¬
            ("Fin! Your icons have been renamed and are ready for upload to your favorite icon market." as string) ¬
                buttons {"Ok"} default button 1
    end if
    logger("-------------------- FIN! --------------------")
end main

-- Gets just the name portion of a file path using bash `basename`
-- @param {string} thePath    A POSIX file path
-- @returns {string} the file name
on basename(thePath)
    return (do shell script ("basename " & quoted form of thePath as string))
end basename

-- Gets the contents of a file using bash `cat`
-- @param {string} A POSIX file path
-- @returns {string}
on cat(theFile)
    return trim(do shell script ("cat " & quoted form of theFile as string))
end cat

-- Verifies AppleScript version
-- @param {number} The minimum required AppleScript version
-- @returns {boolean}
on check_version(required_version)
    if my get_as_version() is greater than or equal to required_version then
        return true
    else
        return false
    end if
end check_version

-- Copies a file using bash `cp`
-- @param {string} fromFile  A POSIX file path to copy from
-- @param {string} toFile    A POSIX file path to save to
-- @returns {boolean}
on cp(fromFile, toFile)
    logger("cp " & quoted form of fromFile & " " & quoted form of toFile as string)
    return do shell script ("cp " & quoted form of fromFile & " " & quoted form of toFile as string)
end cp

-- Formats a date in YEAR-MM-DD HH:MM:SS
-- @param {string} old_date  The date to reformat
-- @returns {string}
on date_format(old_date) -- Old_date is text, not a date.
    set {year:y, month:m, day:d} to date old_date
    tell (y * 10000 + m * 100 + d) as string to text 1 thru 4 & "." & text 5 thru 6 & "." & text 7 thru 8
end date_format

-- Returns the POSIX path to the Desktop folder
-- @returns {string}
on desktop_dir()
    return POSIX path of (path to desktop folder)
end desktop_dir

-- Gets the base folder portion of a file path
-- @param {string} thePath  A POSIX file path
-- @returns {string}
on dirname(thePath)
    return (do shell script ("dirname " & quoted form of thePath as string))
end dirname

-- Expands a Mac OS path to the full POSIX path
-- @param {string} givenPath The Mac-formatte path to expand
-- @returns {string}
on expand_path(givenPath)
    return str_replace(givenPath, "~/", home_dir())
end expand_path

-- Explodes a string to a list
-- @param {string} the_delim   The delimiter on which to split the string
-- @param {string} the_string  The string to split
-- @returns {list}
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

-- Checks whether or not a file exists
-- @param {string} theFile  A POSIX file path
-- @returns {boolean}
on file_exists(theFile)
    tell application "System Events"
        return exists file theFile
    end tell
end file_exists

-- Gets the file extension for a file
-- @param {string} file_name  The file name
-- @returns {string}
on file_ext(aFile)
    return (do shell script ("filename=\"" & aFile & "\"; " & "echo ${filename##*.}"))
end file_ext

-- Checks whether or not a folder exists
-- @param {string} theFile  A POSIX folder path
-- @returns {boolean}
on folder_exists(theFile)
    set theFile to my expand_path(theFile)
    set test to (do shell script "[ ! -d '" & theFile & "' ] || echo 1 ;")
    return (test as number) is 1
end folder_exists

-- Gets the version of AppleScript currently running
-- @returns {number}
on get_as_version()
    return version of AppleScript as number
end get_as_version

-- Gets the file type identifier for a file
-- @param  {string} theFilePath  A POSIX file path for which to get the type code
-- @returns {string}
on get_file_type(theFilePath)
    set theUTI to (current application's NSWorkspace's sharedWorkspace()'s typeOfFile:theFilePath |error|:(missing value))
    if theUTI = missing value then error theError's localizedDescription() as text
    return theUTI as text
end get_file_type

-- Gets the POSIX path to the home directory
-- @returns {string}
on home_dir()
    set homeFolder to (path to home folder)
    return POSIX path of homeFolder
end home_dir

-- Joins list to a string
-- @param {string} delimiter  The delimiter on which to join the list
-- @param {list} pieces          The list of stringst to join
on implode(delimiter, pieces)
    local delimiter, pieces, ASTID
    set ASTID to AppleScript's text item delimiters
    try
        set AppleScript's text item delimiters to delimiter
        logger(pieces as string)
        set the_string to (items of pieces) as string
        set AppleScript's text item delimiters to ASTID
        return the_string --> text
    on error eMsg number eNum
        set AppleScript's text item delimiters to ASTID
        error "Can't implode: " & eMsg number eNum
    end try
end implode

-- Increments a number on the end of a target file name if the name already exists.
-- The function will try 65,535 numbers (max 16-bit number). If the name is still not unique,
-- the function will use a UUID instead.
-- @param {string} theFile  The target POSIX file path
-- @returns {string}
on increment_name(theFile)
    
    set n to 0
    
    -- To keep things from getting out-of-hand, we limit the max number of 
    -- repeats to 65,535 (the max 16-bit integer)
    
    set max to 65535
    
    set theBasename to basename(theFile)
    set theDirname to dirname(theFile)
    set theFileExt to file_ext(theFile)
    set theFileSlug to strip_ext(theBasename)
    
    logger(theFile)
    
    repeat while file_exists(theFile) and n < max
        set theFile to theDirname & "/" & theFileSlug & "-" & n & "." & theFileExt
        logger(theFile)
        set n to n + 1
    end repeat
    
    -- If we exhaust the maximum sequential numbers, in order to insure 
    -- a unique file name, use a name with a short UUID appended
    
    if file_exists(theFile) then
        set theFile to theDirname & "/" & theFileSlug & "-" & short_uuid() & "." & theFileExt
    end if
    
    return theFile
end increment_name

-- Increments a number on the end of a target folder name if the name already exists.
-- The function will try 65,535 numbers (max 16-bit number). If the name is still not unique,
-- the function will use a UUID instead.
-- @param {string} theFolder  The target POSIX folder path
-- @returns {string}
on increment_folder(theFolder)
    
    set n to 0
    
    -- To keep things from getting out-of-hand, we limit the max number of 
    -- repeats to 65,535 (the max 16-bit integer)
    
    set max to 65535
    
    set theBasename to basename(theFolder)
    set theDirname to dirname(theFolder)
    
    logger("increment_folder theFolder : " & theFolder)
    
    repeat while folder_exists(theFolder) and n < max
        set theFolder to theDirname & "/" & theBasename & "-" & n as string
        logger("increment_folder theFolder : " & theFolder)
        set n to n + 1
    end repeat
    
    -- If we exhaust the maximum sequential numbers, in order to insure 
    -- a unique file name, use a name with a short UUID appended
    
    if folder_exists(theFolder) then
        set theFolder to theDirname & "/" & theBasename & "-" & short_uuid() as string
    end if
    
    return theFolder
end increment_folder

-- Loads a config file for the script. The available settings are:
-- -- logging {1 | 0}          1 for true, 0 for false whether to enable logging
-- -- debug  {1 | 0}           1 for true, 0 for false wether to enable debug mode
-- -- output {string}        A POSIX path the root output folder (default is ~/Desktop/iconjar-extractor/)
-- -- password {string}        The clear text administrator password to allow the script to perform privileged tasks (only writing to files/folders)
-- @returns {void}
on load_config()
    if file_exists(to_posix(ini_file)) then
        set settings to my parse_ini(to_posix(ini_file))
        repeat with setting in settings
            log "Name : " & name of setting as string
            log "Value : " & value of setting as string
            if name of setting is "logging" then
                set logging to value of setting
            end if
            if name of setting is "debug" then
                set debug to value of setting
            end if
            if name of setting is "output" then
                set rootOutputFolder to value of setting
            end if
            if name of setting is "password" then
                set myPassword to value of setting
                set has_ini_password to true
            end if
        end repeat
    end if
end load_config

-- Conditionally makes a folder if it does not exist. If it does exist, 
-- returns the POSIX file path (same as the argument), to verify.
-- @param  {string} theFolder  POSIX path to the folder
-- @returns {string}
on make_folder(theFolder)
    if not (my folder_exists(theFolder)) then
        do shell script ("mkdir " & theFolder as string)
    end if
    return theFolder
end make_folder

-- Rename a file using bash `mv`
-- @param {string} fromFile  POSIX path to the original file to rename
-- @param {string} toFile      POSIX path to the desired new location
-- @returns {boolean}
on mv(fromFile, toFile)
    logger("mv " & quoted form of fromFile & " " & quoted form of toFile as string)
    return do shell script ("mv " & quoted form of fromFile & " " & quoted form of toFile as string)
end mv

-- Loads an external script file
-- @param  {string}  scriptName POSIX path to the script to load
-- @returns {boolean} 
on load_script(scriptPath)
    set theScript to (scriptPath as string)
    return (load script theScript)
end load_script

-- Logs messages to Script Editor log if logging is enabled and a log file if debug is enabled.
-- @param {string} theMessage The message to log.
on logger(theMessage)
    set dateString to do shell script ("date '+%Y-%m-%d %H:%M:%S'")
    if logging is true then
        log "[" & dateString & "] - " & quoted form of theMessage
    end if
    if debug is true then
        do shell script ("echo [" & dateString & "] - " & quoted form of theMessage & " >> " & theLogFile as string)
    end if
end logger

-- Alias of `dirname`
-- @param {string} thePath The file/folder for which to get the enclosing folder
-- @returns {string}
on parent_dir(thePath)
    return (do shell script ("dirname " & to_posix(thePath) as string))
end parent_dir

-- Parses an INI format file
-- @param {string} ini_path    The POSIX path to the INI file
-- @returns {list}                  A list of AppleScript dictionaries in format {name: "property", value: "value"}
on parse_ini(ini_path)
    set name_value_pairs to {}
    set file_data to read_file(ini_path)
    set file_data to str_replace(file_data, (ASCII character 13), (ASCII character 10))
    set rows to explode((ASCII character 10), file_data)
    repeat with this_row in rows
        try
            if length of this_row is greater than 1 then
                if first character of trim(this_row) is not ";" then
                    set key_value to explode("=", this_row)
                    copy {name:trim((item 1 of key_value)), value:trim((item 2 of key_value))} to end of name_value_pairs
                end if
            end if
        on error eMsg number eNum
            error "Can't parse ini: " & eMsg number eNum
        end try
    end repeat
    return name_value_pairs
end parse_ini

-- (BEGIN) - Progress bar
-- Creates a progress bar
-- @param {number} steps            The number of steps in the task
-- @param {string} descript           The text to appear on the progress dialog
-- @param {string} descript_add    Additional text to display in the dialog sub-text
-- @returns {void}
on progress_start(steps, descript, descript_add)
    set progress total steps to steps
    set progress completed steps to 0
    set progress description to descript
    set progress additional description to descript_add
end progress_start

-- Updates a progress bar
-- @param {number} n          The current step number
-- @param {number} steps    The number of steps in the current task
-- @param {string} message  The message text
-- @returns {void}
on progress_update(n, steps, message)
    set progress additional description to message & n & " of " & steps
end progress_update

-- Updates the progress bar's completed steps
-- @param {nuber} n  The number of the current step
-- @returns {void}
on progress_step(n)
    set progress completed steps to n
end progress_step

-- Destroys the progress bar
-- @returns {void}
on progress_end()
    -- Reset the progress information
    set progress total steps to 0
    set progress completed steps to 0
    set progress description to ""
    set progress additional description to ""
end progress_end
-- (END) - Progress bar

-- Returns current folder using bash `pwd` (Print Working Directory)
-- @returns {string}
on pwd()
    return do shell script "pwd"
end pwd

on read_file(unixPath)
    return (read unixPath)
end read_file

-- Renames the icons using the metadata from an IconJar file
-- @param {string} theMetaDataFile  The POSIX path to the metadata JSON file
-- @param {string} theIconsFolderPath  The POSIX path to the icons folder
-- @returns {list} List of updated icons JSON
on rename_icons(theMetaDataFile, theIconFolderPath)
    -- set theJsonData to read_file(theMetaDataFile as «class furl»)
    
    logger("Read JSON Data")
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
    logger("Starting repeat loop in rename_icons")
    repeat with theKey in theKeys
        -- Update the progress detail
        progress_update(n, steps, "Processing icon ")
        logger("Processing icon " & n & " of " & steps as string)
        repeat 1 times -- # fake loop
            set theIcon to (iconsDict's valueForKey:theKey) as record
            set theTags to tags of theIcon
            if my trim(theTags) is "" then
                exit repeat
            end if
            set theName to |name| of theIcon
            set theFile to |file| of theIcon
            set newFileName to my tags_to_slug(theTags)
            logger("New Icon File Name : " & newFileName as string)
            set from_file to theIconFolderPath & theFile as string
            set the_ext to my file_ext(from_file)
            set to_file to theIconFolderPath & newFileName & "." & the_ext as string
            set to_file to str_replace(to_file, " ", "-")
            set from_file to str_replace(from_file, " ", "\\ ")
            set mv_script to "mv " & from_file & " " & to_file as string
            logger("Do Shell Script : " & mv_script as string)
            do shell script mv_script
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
    logger("Finished renaming icons")
    progress_end()
    
    return iconUpdates
end rename_icons

-- Makes a path POSIX safe. Replaces spaces and commas with dashes.
-- @param {string} theFileName   The file name to make safe.
-- @param {string} theFilePath     The path to the file
-- @returns {string}                     The new name
on safe_file_name(theFileName, theFilePath)
    set theCommaTest to str_replace(theFileName, ",", "-")
    set theSpaceTest to str_replace(theFileName, " ", "\\ ")
    if theCommaTest is not equal to theFileName or theSpaceTest is not equal to theFileName then
        set newFileName to str_replace(theFileName, ",", "-")
        set newFileName to str_replace(newFileName, " ", "\\ ")
        set newFilePath to theFileFolder & newFileName as string
        do shell script ("mv " & theFilePath & " " & newFilePath)
    end if
end safe_file_name

-- Makes a path POSIX safe. Replaces spaces and commas with dashes.
-- @param {string} theFilePath  The path to make POSIX safe.
-- @returns {string}                  The new name
on safe_file_path(theFilePath)
    set safe_path to str_replace(theFilePath, " ", "\\ ")
    return safe_path
end safe_file_path

-- A short, unique string
-- @returns {string}
on short_uuid()
    set uuid to (do shell script "uuidgen")
    set uuid to my str_replace(uuid, "-", " ")
    set uuid to (do shell script "A=\"" & uuid & "\" ; echo \"${A##* }\";")
    return uuid
end short_uuid

-- Replace a needle in haystack
-- @param {string} theText        The haystack
-- @param {string} oldString    The string to be replaced
-- @param {string} newString    The string with which to replace oldString
-- @returns {string}
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

-- Strips file extension
-- @param {string} file_name    The file name from which to strip the extension
-- @returns {string}
on strip_ext(file_name)
    return (do shell script ("filename=\"" & file_name & "\"; " & "echo ${filename%.*}"))
end strip_ext

-- Transforms a string to uppercase
-- @param {string} theString    The string to transform
-- @returns {string}
on str_to_upper(theString)
    return (do shell script "awk '{ print toupper($0) }' <<< \"" & theString & "\"")
end str_to_upper

-- Transforms a string to lowercase
-- @param {string} theString    The string to transform
-- @returns {string}
on str_to_lower(theString)
    return (do shell script "awk '{ print tolower($0) }' <<< \"" & theString & "\"")
end str_to_lower

-- Converts a comma-separated list of tags to a dash-delimited slug with no spaces
-- @param {string} tags        The comma-separated liste of tags
-- @returns {string}
on tags_to_slug(tags)
    
    set the_slug to tags
    
    set unsafe_chars to {",", "\\", " ", ".", "/"}
    set safe_char to "-"
    
    repeat with bad_char in unsafe_chars
        set the_slug to str_replace(the_slug, bad_char, safe_char)
    end repeat
    return my str_to_lower(the_slug)
end tags_to_slug

-- Converts a path to POSIX path
-- @param {string} thePath        The path to convert to POSIX (can be an alias or path)
-- @returns {string}
on to_posix(thePath)
    return ((POSIX path of my expand_path(thePath)) as string)
end to_posix

-- Converts a POSIX path to an alias
-- @param {string} thePath        The POSIX path to convert to an alias
-- @returns {string}
on to_alias(thePath)
    (POSIX file (my expand_path(thePath))) as alias
end to_alias

--  Trims white space from both ends of a string
-- @param {string} someText    The string to be trimmed
-- @returns {string}
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

-- Returns name of current user using bash `whoami`
-- @returns {string}
on whoami()
    return do shell script "whoami"
end whoami



