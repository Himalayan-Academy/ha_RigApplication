script "xmlrpc"

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
        rigLogMessage "debug", "XML-RPC Library Loaded"
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
-- rigLogMessage "debug", "XML-RPC Library Loaded" ------------ rabit

# DECLARE LOCAL VARIABLES
local sServer
local sLastXMLRPCResponse

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialxmlrpcConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialxmlrpcConfig

command xmlrpcSetServer pServer
	put pServer into sServer
	rigLogMessage "debug", "Setting XML-RPC Server to" && sServer
end xmlrpcSetServer

--> XML-RPC Suite

function xmlrpcAddParam pParam
	switch
		case pParam is a number
			return "<param><value><int>"&pParam&"</int></value></param>"
		break
		default
			return "<param><value><string>"&pParam&"</string></value></param>"
		break
	end switch
end xmlrpcAddParam

function xmlrpcDecodeResponseToArray pResponse
	put ConvertXMLToArray(pResponse, "UTF-8") into theArray 
	return theArray
end xmlrpcDecodeResponseToArray

function xmlrpcDecodeStruct pA
	repeat for each key tMember in pA
		put pA[tMember]["name"] into tK
		put pA[tMember]["value"] into tValA
		switch the keys of tValA
			case "array"
				put xmlrpcDecodeArray(tValA["array"]) into tRetValA[tK]
			break
			case "struct"
				put xmlrpcDecodeStruct(tValA["struct"]) into tRetValA[tK]
			break
			default
			put tValA[the keys of tValA] into tRetValA[tK]
			break
		end switch
	end repeat
	return tRetValA
end xmlrpcDecodeStruct

function xmlrpcDecodeArray pA
	repeat for each key tData in pA["data"]
		add 1 to x
		put pA["data"][tData] into tValA
		switch the keys of tValA
			case "array"
				put xmlrpcDecodeArray(tValA["array"]) into tRetValA[x]
			break
			case "struct"
				put xmlrpcDecodeStruct(tValA["struct"]) into tRetValA[x]
			break
			default
			put tValA[the keys of tValA] into tRetValA[x]
			break
		end switch
	end repeat
	return tRetValA
end xmlrpcDecodeArray

function xmlrpcLastResponse
	return sLastXMLRPCResponse
end xmlrpcLastResponse

function callXMLRPC pMethod
	repeat with x = 2 to the paramcount
		put xmlrpcAddParam(param(x)) after tParams
	end repeat
	put the merge of "<methodCall><methodName>[[pMethod]]</methodName><params>[[tParams]]</params></methodCall>" into tXMLRPCRequest
	--rigLogMessage "debug", "XML-RPC Server:" & sServer
	--rigLogMessage "debug", "XML-RPC Request:" & tXMLRPCRequest
	post tXMLRPCRequest to url sServer
	if the result is not empty then
		rigLogMessage "debug", "Result:" & the result
	end if
	rigLogMessage "debug", "It:" & it
	put it into sLastXMLRPCResponse
	return xmlrpcDecodeResponseToArray(it)
end callXMLRPC

	
