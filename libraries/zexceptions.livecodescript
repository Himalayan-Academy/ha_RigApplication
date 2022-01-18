script "zexceptions"

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
        rigLogMessage "debug", "Z Exceptions Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


-------------------- rabit
# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialzExceptionsConfig pConfig

end rigRunInitialzExceptionsConfig

-- put gRigA["BASEPATH"] into gRigA["BASEPATH"]

-- if gRigA["BASEPATH"] is "gRigA["BASEPATH"]" then
	-- put "No direct script access allowed."
	-- exit to top
-- end if
----------------------

##
# revIgniter
#
# An application development framework for LiveCode
# modeled on CodeIgniter.
#
# @package		revIgniter
# @author		  rabit@revigniter.com
# @copyright	Copyright (c) 2009 - 2011, dimensionB Bitter u. Bitter GmbH
# @license		http://revigniter.com/userGuide/license.html
# @link		    http://revigniter.com
##

## ------------------------------------------------------------------------

##
# revIgniter Exceptions Library
#
#
# @package		revIgniter
# @subpackage	Libraries
# @category	  Exceptions
# @author		  rabit@revigniter.com
# @link		    http://revigniter.com/userGuide/general/controllers.html
##


# DECLARE VARIABLES




----------------------------------------------------------------------
--| COMMAND rigLogException
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-06-09
--| Last Mod: 28-06-09
--| Requires: rigFetchControllerHandler(), rigLogMessage
--|
--| Summary:  This command logs Rev error messages.
--| 
--| Format:  rigLogException param1, param2, param3, param4
--|
--| Parameters: string <pErrorData>, bool <pDisplayError>, string <pFile>, string <pMethod>
--|
--| Return: void
----------------------------------------------------------------------

command rigLogException pErrorData pDisplayError pFile pMethod
	if pFile is empty then
		-- put gRigA["Controller]" into tFile
      put gRigA["Controller"] into tFile ------------ rabit
	else
		put pFile into tFile
	end if
	if pMethod is empty then
		put rigFetchControllerHandler() into tMethod
	else
		put pMethod into tMethod
	end if

	put "RevError - Current File:" && tFile & ", Current Method:" && tMethod & CR & pErrorData into tErrorData
	rigLogMessage "error", tErrorData, pDisplayError
end rigLogException

----------------------------------------------------------------------
--| COMMAND rigShow404Page
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-06-09
--| Last Mod: 13-09-09
--| Requires: rigLogMessage, rigShowErrorPage
--|
--| Summary:  404 Page Not Found Handler.
--| 
--| Format:  rigShow404Page param1
--|
--| Parameters: mixed <pPage>
--|
--| Return: void
----------------------------------------------------------------------

command rigShow404Page pPage
	if pPage is an array then
		put pPage["page"] into tPage
	else
		put pPage into tPage
	end if
	
	if char 1 of tPage is not "/" then
		put "/" before tPage
	end if
	
	aagRedirectIfFound tPage

	put  "404 Page Not Found" into tHeading
	put ("The page you requested was not found. <br /><br />" & tPage) into tMessage

	rigLogMessage "error", "404 Page Not Found --> " & tPage 
	put rigShowErrorPage(tHeading, tMessage, "error404", 404)
	exit to top
end rigShow404Page

----------------------------------------------------------------------
--| COMMAND aagRedirectIfFound pPage
--|
--| Author: aag
--| Version:  1.0
--| Created: 23-11-12
--| Last Mod: 23-11-12
--| Requires: rigLogMessage
--|
--| Summary:  Loads a redirect map from a file. If the page matches 
--| an entry there then the user is redirected.
--|
--| OBS: This function was added to the show404 call.
--| 
--| Format:  aagRedirectIfFound param1
--|
--| Parameters: mixed <pPage>
--|
--| Return: void
----------------------------------------------------------------------

command aagRedirectIfFound pPage
	if pPage is an array then
		put pPage["page"] into tPage
	else
		put pPage into tPage
	end if
	
	put url ("binfile:" & $_SERVER["DOCUMENT_ROOT"] & "/html/monastery/info/redirectmap.xml") into tRedirectMapXML
	put revCreateXMLTree(tRedirectMapXML, true, true, false) into tXML
	if tXML is not a number then
		exit aagRedirectIfFound
	end if
	
	put empty into tNewLink
	
	put revXMLNumberOfChildren(tXML, "/map", "redirect", 1) into tNumberOfEntries
	repeat with x = 1 to tNumberOfEntries
		put "/map/redirect["&x&"]" into tNode
		put revXMLNodeContents(tXML, (tNode & "/from")) into tFrom
		put revXMLNodeContents(tXML, (tNode & "/to")) into tTo
		put revXMLAttribute(sXML, tNode, "match") into tMatchingType
		if "xmlerr" is in tMatchingType then
			put "contains" into tMatchingType
		end if
		switch tMatchingType
			case "contains"
				if tFrom is in tPage then
					put tTo into tNewLink
					exit repeat
				end if
			break
			case "regex"
				if matchText(tPage, tFrom) then
					put tTo into tNewLink
				end if
			break
		end switch
	end repeat
	
	if tNewLink is empty then
		exit aagRedirectIfFound
	end if
		

	rigLogMessage "error", "302 Redirect match" && tPage &&"matched"&& tFrom &&"redirected to --> " & tNewLink 
	
	put header "Status: 302"
	put header "Location:" && tNewLink
	put "Redirecting to" && tNewLink
	exit to top
end aagRedirectIfFound




----------------------------------------------------------------------
--| FUNCTION rigShowErrorPage
--|
--| Author: rabit
--| Version:  1.1
--| Created: 29-06-09
--| Last Mod: 13-09-09
--| Requires: error files
--|
--| Summary: General Error Page
--|                    This function takes an error message as input
--|                    (either as a string or an array) and displays
--|                    it using the specified template.
--| 
--| Format:  rigShowErrorPage(param1, param2, param3)
--|
--| Parameters: string <pHeading>, string <pMessage>, string <pTemplate>, integer <pStatusCode>
--|
--| Return: string
----------------------------------------------------------------------

function rigShowErrorPage pHeading pMessage pTemplate pStatusCode
	-- put pHeading into gRigA["ErrorData]"["heading"]
   put pHeading into gRigA["ErrorData"]["heading"] -------------- rabit
	put pMessage into tMessage

	if pTemplate is empty then
		put "errorGeneral" into tTemplate
	else
		put pTemplate into tTemplate
	end if

	if pStatusCode is empty then
		put 500 into tStatusCode
	else
		put pStatusCode into tStatusCode
	end if

	rigSetStatusHeader tStatusCode

	if tMessage is an array then
		put "<p>" into tErrorMsg
		repeat for each key tKey in tMessage
			put tMessage[tKey] & "</p><p>" after tErrorMsg
		end repeat
		delete char -3 to -1 of tErrorMsg
	else 
		put "<p>" & tMessage & "</p>" into tErrorMsg
	end if

	-- put tErrorMsg into gRigA["ErrorData]"["message"]
   put tErrorMsg into gRigA["ErrorData"]["message"] ------------ rabit

	put gRigA["APPPATH"] & "errors/" & tTemplate & gRigA["EXT"] into tErrorFilePath
	put URL format("binfile:%s", tErrorFilePath) into tBuffer

	put merge(tBuffer) into tOutput
	return tOutput
end rigShowErrorPage



--| END OF Exception.lc
--| Location:  ./system/libraries/Exception.lc
----------------------------------------------------------------------