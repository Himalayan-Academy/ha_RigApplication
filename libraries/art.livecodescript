script "art"

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
        rigLogMessage "debug", "Art Library Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues -------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "Art Library Loaded" ---------------- rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialArtConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialArtConfig


function findArtByArray pA
	rigDbWhere pA
	combine pA by "," and "="
	rigLogMessage "debug", "looking for Art:" && pA
	put rigDbGet("item") into tQuery
	if tQuery["numrows"] > 0 then
		repeat with x = 1 to tQuery["numrows"]
			put rigDbRow(x) into tRetA[x]
			-- get the channels of distribution (mainly print version)
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
end findArtByArray

function folderForArt pA
	set the itemdel to slash
	put item 2 of pA["media_type"] into tType
	return ($_SERVER["DOCUMENT_ROOT"] & "/media/art/" & tType &"/"& pA["file_id"]) 
end folderForArt

function getArtFormat pA, pFormat
	repeat for each key tK in pA["formats"]
		if  pA["formats"][tK]["format_name"] is pFormat then
			return pA["formats"][tK]
		end if
	end repeat
	return empty
end getArtFormat

function getPathForArt pA
	repeat for each key k in pA["formats"]
		switch
		case "_ful" is in pA["formats"][k]["filename"]
			put  pA["formats"][k] into tFormatA
		break
##### BR: 2104-12-17 for reasons we do not understand the case statement drop thru to 
## the "_med" value even if we have a "_ful" version in the items format table.
## by commenting these out, it defaults to "_ful" which we have in all cases.
		#case "_lrg" is in pA["formats"][k]["filename"]
		#	put  pA["formats"][k] into tFormatA
		#break
		#case "_med" is in pA["formats"][k]["filename"]
		#	put  pA["formats"][k] into tFormatA
		#break
		end switch
	end repeat
	get (folderForArt(pA) & "/" & tFormatA["filename"] )
	replace $_SERVER["DOCUMENT_ROOT"] with empty in it
	return it
end getPathForArt
