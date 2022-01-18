script "Metaweblog"

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
        rigLogMessage "debug", "MetaWeblog XML-RPC Library Loaded"
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
-- rigLogMessage "debug", "MetaWeblog XML-RPC Library Loaded" ---------- rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialMetaWeblogConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialMetaWeblogConfig

--> MetaWeblog Suite

function metaWeblog.getRecentPosts pBlogID, pUser, pPassword, pNumberOfPosts
	put callXMLRPC("metaWeblog.getRecentPosts", pBlogID, pUser, pPassword, pNumberOfPosts) into tPostsA
	return xmlrpcDecodeArray(tPostsA["methodResponse"]["params"]["param"]["value"]["array"])
end metaWeblog.getRecentPosts


	
		