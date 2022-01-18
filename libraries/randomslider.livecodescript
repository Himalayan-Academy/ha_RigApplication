script "randomslider"

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
        rigLogMessage "debug", "Random Slider Library Loaded"
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
-- rigLogMessage "debug", "Random-Slider Library Loaded" -------------- rabit

# DECLARE LOCAL VARIABLES


# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
-- command rigRunInitialepubConfig
command rigRunInitialRandomsliderConfig pConfig ------------- rabit
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
-- end rigRunInitialepubConfig
end rigRunInitialRandomsliderConfig ---------- rabit


function emitDynamicRandomSlideShow  pPath

put  $_SERVER["DOCUMENT_ROOT"] & pPath into tImagesPath


	
  # Brahmanathaswami: 2012-09-01
  # this is  typical function that is using what could probably be some utilities
  # the generic functions piled together here are:
  # 1. get files from some folder
  # 2. set up Galleria slideshow options (but they are not the same for each theme)
  # but this is getting redundant.. we may want to, for example get a slide show 
  # by getting infor from the database and the using a different theme to show
  # for example a lot of art in a slideshow instead of a gallery/catalog page view.
  # and it would not need to be random in that case.
  # This function here is more set up as a "decorative" feature to 
  # show images on a page with no controls that rotate thru a set
  
		 # Create the metadata for the JSON Variable here
		 # idea is to get a random series each time any page loads
		 # sort lines of myVar by random(the number of lines of myVar)
		 
		 put the defaultFolder into tCurrentFolder
		 set the defaultfolder to tImagesPath
		 put the files into tSliderImages
		
		 				 
		 sort lines of tSliderImages by random(the number of lines of tSliderImages)
		 filter tSliderImages without "*.js"		 	
		 
		repeat for each line x in tSliderImages		
			put pPath &"/" & x  & cr after tJSONData		
		end repeat
	 
	rigLogMessage "debug", "tJSONData: " && tJSONData
		put the seconds into tPoorMansGUID
		
		 set the defaultFolder to tCurrentFolder
		 
		put "726" into tOptions["width"]
		put "275" into tOptions["height"]
		put "true" into tOptions["imageCrop"]
		put "false" into tOptions["thumbnails"]
		put "false" into tOptions["showCounter"]
		put "2500" into tOptions["autoplay"]
		put "false" into tOptions["showInfo"]
		put "'fade'" into tOptions["transition"]
		put "1000" into tOptions["transitionSpeed"]
		
		put rigDynamicGalleriaData(tJSONData,tOptions,tPoorMansGUID,headerpix) into gData["slideShow"]	
		rigLogMessage "debug", "gDataSlideShow: " && gData["slideShow"]
		 		
end emitDynamicRandomSlideShow