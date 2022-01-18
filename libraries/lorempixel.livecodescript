script "lorempixel"

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
        rigLogMessage "debug", "LoremPixel Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


/*

Lorem Pixel Temporary Image Library

Author: Andre Alves Garzia (andre@andregarzia.com)
30/01/12

License: BSD 

More information about lorem pixel at http://lorempixel.com/

*/


# LOGGING
-- rigLogMessage "debug", "LoremPixel Library Loaded" ------------- rabit

# DECLARE LOCAL VARIABLES

command rigRunInitialLoremPixelConfig pConfig

end rigRunInitialLoremPixelConfig

function loremPixel pType, pWidth, pHeight, pGrayBoolean, pText
	put "http://lorempixel.com/" into tURL
	
	if pGrayBoolean is true then
		put "g/" after tURL
	end if
	
	put pWidth & "/" after tURL
	put pHeight & "/" after tURL
	put pType & "/" after tURL
	
	if pText is not empty then
		replace " " with "-" in pText
		put pText after tURL
	end if
	
	return tURL
end loremPixel 

	
	