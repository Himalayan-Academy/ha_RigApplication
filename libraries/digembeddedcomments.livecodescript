script "digembeddedcomments"

global gRigA,gData
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
        rigLogMessage "debug", "Dig Embedded Comments Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack

/* Brahmanathaswami 2012/3/25

# this is acopy of site.lc with slight modifications for 
# testing purposes

*/



# RUN INITIAL CONFIGURATION PROCEDURES
# Whether Need or Not
command rigRunInitialDigEmbeddedCommentsConfig pConfig
end rigRunInitialDigEmbeddedCommentsConfig

function DigEmbeddedComments

local tLinkedTaskList
 
 # First get all files that are either .html or .xml files 
      put format  ("tree -a -f -i -P \"*.xml|*.html\" --noreport /home/devhap/public_html/html") into tShell
      put shell(tShell) into tFileNames
      repeat for each line x in tFileNames
	      if ( (x contains ".html") OR (x contains ".xml") ) then	  
		       if not (isNumber( char -6 of x) ) then   
			      put x  & cr after tTargetFiles
		      end if
	      end if
      end repeat
      
 # filters out certain directories so we don't read and parse files unecessarily
     REPEAT FOR each line x in tTargetFiles
      if x contains "userGuide" then next Repeat
      if x contains "mc-daily_lesson_html" then next Repeat
          if x contains "mc-daily_lesson_source" then next Repeat
       put x & cr  after tOutput
    END repeat 
    
    repeat for each line y in tOutput
			put 0 into tFoundFlag
			put url ("file:"& y) into tSourceString
			put "<comment>,<task><CU>,??, editing team" into tTargets
		   repeat for each item tT in tTargets
			      if tSourceString contains tT then	
			      put 1 into tFoundFlag		      			       
		         end if		      
	      end repeat
	      if tFoundFlag= 1 then
	       put digForTasks(y,tSourceString) after tLinkedTaskList
		 end if			     
      end repeat
 
    return tLinkedTaskList
    
    end DigEmbeddedComments
    
function digForTasks pPath,tSourceString  
          
      # Create a link first
      put "<br />" & cr into tTaskList
      put makeFileLink(pPath) & "<br />" & cr after tTaskList
      
      # make bullet List
       put "<ul>" & cr   after tTaskList
               
			put "<comment>/<task>/??/<CU>/editing team" into tTargets
			set the itemdel to "/"
		   repeat for each item tT in tTargets	
		     put	 line ( lineOffset (tT,tSourceString) ) of tSourceString into tTask
		        if tTask <> empty then
		            if tTask <> tPreviousTask then
					     put "<li>" & tTask & "</li>" after tTaskList
				     end if
			     end if
			     put tTask into tPreviousTask
	       end repeat
	       	put "</ul>" & cr after tTaskList
	       	
	       	# undo comments from HTML for display here
	       	replace "<!--" with "" in tTaskList
	       	replace "-->" with "" in tTaskList
         return tTaskList
end digForTasks

function makeFileLink pPath
          set the itemdel to "/"
          delete item 1 to 4 of pPath
           put pPath into tFileLInk
           delete item 1 of tFileLInk
           put "/" before tFileLInk
          replace "index.xml" with "" in tFileLInk
          replace ".html" with "" in tFileLink
          replace ".xml" with "" in tFileLink
          replace "gurulineageandphilosophy" with "satgurus" in tFileLink        
          put format ("<a href=\"%s\">%s</a>",tFileLink,pPath) into tLinkedFile
          return tLinkedFile
end makeFileLink
    
   