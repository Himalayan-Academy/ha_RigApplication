script "generateslideshow"

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
        rigLogMessage "debug", "Generate Slideshow Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


------------------------- rabit
# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialGenerateslideshowConfig pConfig

end rigRunInitialGenerateslideshowConfig
--------------------------


# This is a generic script to generated the galleria
# stage by reading a folder of images
# and building the stage dynamically.
# we need to be able to control the size if of the rect

global gGalleryImagesPath
 
function generateSlideShow gGalleryImagesPath
   
   # Assume simple CMS images plus file with caption.
   # we have two flavors of caption file names   "someImage.txt"  and "someImage.jpg.txt"

 
   put "No" into tThumbsIncluded     
   set the itemdel to "/"
   put ("/" & (item 5 to -1 of gGalleryImagesPath) &"/") into tImagePathStem 

   set the defaultfolder to gGalleryImagesPath
   put the files into tFiles
   sort tFiles
   # first line will be image, second line will be caption if there is on etc.
   # need to test each online
   
   switch tThumbsIncluded
      
      case "No"
         repeat for each line x in tFiles
            set the itemdel to "."
            put item -1 of x into tType
            if tType is among the words of "jpg png jpeg gif"  then 
               # its an image; close previous image and start a new one
              
               put format (" />" & cr & cr & "<img src=\"" & tImagePathStem & x & "\" title=\"\"") after tGalleryDiv
            end if   
            # it is a caption we want to get text from disk now:
            if (item -1 of  x) is "txt" then 
               put url ("file:" & gGalleryImagesPath & "/" & x) into tCaption   
               replace quote with "&quot;" in tCaption
               put format (" alt=\"" & tCaption & "\"  ") after tGalleryDiv
            end if 
            set the itemdel to "/"
         end repeat
         # close the last tag
         put " />" after tGalleryDiv
         # wipe initial image closing tag
         Delete line 1 of tGalleryDiv
         # 
         break
         
      case "Yes" #TBD later when we dig folders with thumbs and images 
         
         break
   end switch

 return tGalleryDiv

  

end generateSlideShow
