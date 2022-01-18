script "app"

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
        rigLogMessage "debug", "App Model Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "App Model` Library Loaded" ---------- rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialAppConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialAppConfig


function findAppByArray pA
	rigDbWhere pA
	combine pA by "," and "="
	rigLogMessage "debug", "looking for app:" && pA
	put rigDbGet("item") into tQuery
	if tQuery["numrows"] > 0 then
		repeat with x = 1 to tQuery["numrows"]
			put rigDbRow(x) into tRetA[x]
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("channel") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["channels"][y]
				end repeat
			end if
			-- get the available formats
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("item_format") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["formats"][y]
				end repeat
			end if
			-- go back to the book query
			put rigDbGet("item") into tQuery
		end repeat
	  return tRetA
	else
		return false
	end if
end findAppByArray

function folderForApp pA
	set the itemdel to slash
	put item 2 of pA["media_type"] into tType
	return ($_SERVER["DOCUMENT_ROOT"] & "/media/apps/" & tType &"/"& pA["file_id"]) 
end folderForApp

function getAppFormat pA, pFormat
	repeat for each key tK in pA["formats"]
		if  pA["formats"][tK]["format_name"] is pFormat then
			return pA["formats"][tK]
		end if
	end repeat
	return empty
end getAppFormat

