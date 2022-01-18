script "markdown"

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
        rigLogMessage "debug", "Markdown Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


/*

This is a Markdown wrapper library.
More information about Markdown: http://daringfireball.net/projects/markdown/

Author: Andre Alves Garzia (andre@andregarzia.com)
30/01/12

License: BSD 

*/


# LOGGING
-- rigLogMessage "debug", "Markdown Library Loaded" ------------ rabit

# DECLARE LOCAL VARIABLES

command rigRunInitialMarkdownConfig pConfig
	if markdownAvailable() is false then
		rigLogMessage "error","markdown is not available."
	end if
end rigRunInitialMarkdownConfig


function markdownVersion
	return shell("markdown --shortversion")
end markdownVersion

function markdownAvailable
	get  markdownVersion()
	if it is a number then
		return true
	else
		return false
	end if
end markdownAvailable

function markdown pText
	put tempname() into tTextFile
	put tempname() into tOutFile
	put pText into url ("binfile:" & tTextFile)
	put shell("markdown" && tTextFile && ">>" & tOutFile) into tResult
	delete file tTextFile
	put url ("binfile:" & tOutFile) into tOut
	delete file tOutFile
	return tOut
end markdown
