script "searchreplaceinfiles"

global gRigA
local sStackInUse

on libraryStack
  if (gRigA is not an array) and (the environment is "server") then
    put "No direct script access allowed."
    exit to top
  end if

  if the short name of the target = the short name of me then
    if sStackInUse <> TRUE then
      put TRUE into sStackInUse

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Search Replace in Files Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues -------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack

/* Brahmanathaswami 2012/10/13
# Be forewarned. This script is dangerous and cannot be undone
# Be sure you have a complete back up of the directory you are working in!
# this is run from the manager controller /manager/search-replace
# but you can use it just to search only 
# by commenting out the replacement cmds(see below)

*/



# RUN INITIAL CONFIGURATION PROCEDURES
# Whether Need or Not
command rigRunInitialsearchreplaceinfilesConfig pConfig
end rigRunInitialsearchreplaceinfilesConfig

local tCount

function SearchReplaceInFiles

# set up search and replace strings
if $_GET is empty then
		put "ganesha-puja" into tStringToFind
	else
		put $_GET into tStringToFind
end if



#Leave the following line commented out when not using, so that this script will not change anything:

-- put "livespiritually/home-puja" into tStringToInsert
 
 # First get all files that are either .html or .lcl files; you can look into the code from here
 # if you point the shell tree to the application directory; for JS or CSS point to the assets/ directory
 # comment out the ones you do not want to check. 
 # this i
 
  --put format  ("tree -a -f -i -P \"*.xml|*.lc|*.html\" --noreport /home/devhap/public_html/html") into tShell
   --put format  ("tree -a -f -i -P \"*.xml|*.lc|*.html|*.js|*.css\" --noreport /home/devhap/public_html/assets/") into tShell
     # look for stuff html pages folder
      put format  ("tree -a -f -i -P \"*.xml|*.lc|*.html\" --noreport /home/devhap/public_html/html/") into tShell
   
    --put format  ("tree -a -f -i -P \"*.xml|*.lc|*.html\" --noreport /home/devhap/public_html/system/application/ha") into tShell
      put shell(tShell) into tFileNames
           repeat for each line x in tFileNames	  
            
			      put x  & cr after tTargetFiles
		    
      end repeat
          
    repeat for each line y in tTargetFiles
			put url ("file:"& y) into tSourceString
			if tSourceString contains tStringToFind then
				add 1 to tCount
				put y & "<br />" & cr after tFoundFiles
				
# to just search only, comment out the following 2  lines	
				
	-- replace tStringtoFind with tStringToInsert in tSourceString
	-- put tSourceString into url  ("file:"& y)	 	
		
			end if	     
      end repeat
      if tCount<1 then put "0" into tCount
      
      put "Looked for: " & tStringToFind &". We found <b>" & tCount & "</b> files: " & "<br />" & cr before tFoundFiles
    
    return  tFoundFiles
           
end SearchReplaceInFiles