script "taka"

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
        rigLogMessage "debug", "TAKA Library Loaded"
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
-- rigLogMessage "debug", "TAKA Library Loaded" --------------- rabit

# DECLARE LOCAL VARIABLES
constant kBlogID = "2"
constant kUsername = "taka"
constant kPassword = "108koyil"

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialtakaConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
			rigLoaderLoadLibrary "xmlrpc"
			rigLoaderLoadLibrary "wp"
			rigLoaderLoadLibrary "metaweblog"
			xmlrpcSetServer "http://himalayanacademy.com/blog/taka/xmlrpc.php"
end rigRunInitialtakaConfig

--> Wordpress Suite

function takaGetRecentPosts pNumberOfPosts
	return metaweblog.getRecentPosts(kBlogID, kUsername, kPassword, pNumberOfPosts)
end takaGetRecentPosts


	
		