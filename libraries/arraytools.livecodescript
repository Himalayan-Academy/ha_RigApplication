script "arraytools"

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
        rigLogMessage "debug", "Array Tools Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "Array Tools Library Loaded" -------------- rabit

# DECLARE LOCAL VARIABLES
local sServer

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialarraytoolsConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialarraytoolsConfig

--> XML-RPC Server Suite


	
/*
lib.aag.arraytools
by
Andre Alves Garzia
(andre@andregarzia.com)
2011
*/

global sXML
global sXA

function xaLastError
   return sXA["last error"]
end xaLastError

function xmltoarray pXML
	if pXML is a number then
		put pXML into sXML
	else
   put revCreateXMLTree(pXML, true, true, false) into sXML
   if sXML is not a number then
      put sXML into sXA["last error"]
      return empty
   end if
	end if
  return xaConvertNodeToArray(revXMLRootNode(sXML))
end xmltoarray

function arraytoxml pA
   return format("<?xml version=\"1.0\"?>\n") & xaConvertArrayToXML(pA)
end arraytoxml


function xaConvertArrayToXML pA
   repeat for each key tK in pA
      if the keys of pA[tK] is not empty then
         put xaConvertArrayToXML(pA[tK]) into tContent
      else
         put pA[tK] into tContent
      end if
      set the itemdel to "["
      put item 1 of tK into tK
      if tK is a number then
         put "item_" before tK
      end if
      put empty into tEncoding
      if "_base64" is in tK then
         put the base64encode of tContent into tContent
         replace "_base64" with empty in tK
         put "base64" into tEncoding
      end if
      if tEncoding is empty then
         put format("<%s>%s</%s>", tK, tContent, tK) after tResponse
      else
         put format("<%s encoding=\"%s\">%s</%s>", tK, tEncoding, tContent, tK) after tResponse
      end if
   end repeat
   return tResponse
end xaConvertArrayToXML

function xaNodeName pNode
   set the itemdel to slash
   return item -1 of pNode
end xaNodeName

function xaConvertNodeToArray pNode
   put revXMLNumberOfChildren(sXML, pNode,,1) into tChildCount
   if tChildCount is 0 then
      -- found a leaf!
      put xaNodeName(pNode) into tKey
      if char 1 to 5 of tKey is "item_" then
         replace "item_" with empty in tKey
      end if
      put revXMLNodeContents(sXML, pNode) into tContent
      switch revXMLAttribute(sXML, pNode, "encoding")
         case "base64"
            put the base64decode of tContent into tA[tKey]
            break
         default
            put tContent into tA[tKey]
            break
      end switch
      return tA
   end if
   put xaNodeName(pNode) into tRootKey
     if char 1 to 5 of tRootKey is "item_" then
         replace "item_" with empty in tRootKey
      end if
   put revXMLFirstChild(sXML, pNode) into tNode
   repeat while tNode is not empty
      put xaConvertNodeToArray(tNode) into tA2
      repeat for each key tK in tA2
         put tA2[tK] into tA[tRootKey][tK]
      end repeat
      put revXMLNextSibling(sXML, tNode) into tNode
   end repeat
   return tA
end xaConvertNodeToArray
