script "dottedslideshow"

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
        rigLogMessage "debug", "Dotted Slideshow Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ----------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



------------ rabit
# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialdottedslideshowConfig pConfig

end rigRunInitialdottedslideshowConfig
------------





# We are building a simple slideshow using HappyCogs Dotted
# fixed image size model. This library can be used to instantiate one of these
# simple sliders anywhere. 
# The width and height are 726 X 448 as defined by the CSS except at the top
# the CSS is unforgiving, photos must be sized accurately or they will be distorted.
# Note this is not for the home page heros. which is a unique slideshow DOM
# for the home page only.

# the gSlidesPath must be a full path from root "/home/etc..." ending in a slash "/"

# We just iterate thru the slides and captions and build these figures, no alts.

#  <figure class="slide">
#   <img src="FPO/slides-example-1.jpg" alt="photo of ..." />
#    <figcaption class="caption">Full Width Image: 726px Wide</figcaption>
# </figure>

command dottedSlideShow pGalleryImagesPath, pKey
	put dottedSlideShow(pGalleryImagesPath) into tGalleryImages
	put rigLoadView("media/dottedSlideshow",TRUE) into tSlideShow
	replace "###SLIDES###" with tGalleryImages in tSlideShow
	put tSlideShow into gData[pKey]	
end dottedSlideShow
 
function dottedSlideShow gSlidesPath
 
   # Assume simple CMS images plus file with caption.
   # we have two flavors of caption file names   "someImage.txt"  and "someImage.jpg.txt"
   
   # set up our wrapper chunks first, this saves building them later
   
   put format ("<figure class=\"slide\">" & cr & "<img src=\"") into tStartSlide
   put format ("\" />" & cr &"<figcaption class=\"caption\">") into tStartCaption
   put format ("</figcaption>" &"</figure>" & cr & cr) into tEndCaption
   
   
    set the itemdel to "/"
     put  gSlidesPath into tImagePathStem 
     delete item 1 to 4 of tImagePathStem

   set the defaultfolder to gSlidesPath
   put the files into tFiles
   sort tFiles
  
   # first line will be image, second line will be caption if there is on etc.
   # need to test each line
   
         repeat for each line x in tFiles
            set the itemdel to "."
            put item -1 of x into tType
            if tType is among the words of "jpg png jpeg gif"  then 
               # its an image; close previous image and start a new one
              
               put tEndCaption & tStartSlide & ("/"&tImagePathStem&x) & tStartCaption after tSlideShowDiv
            end if  
             
            # it is a caption we want to get text from disk now
            # append to the chunk, close the caption and we are done.
            # if there is no caption, the figcaption is simply empty
            
            if (item -1 of  x) is "txt" then 
               put url ("file:" & gSlidesPath & x) into tCaption   
               replace quote with "&quot;" in tCaption
               put tCaption  after tSlideShowDiv
            end if 
        
         end repeat    
         
            
         # close final caption
         put tEndCaption after tSlideShowDiv
         
         # wipe initial closing tag
         Delete line 1 of tSlideShowDiv
        

 return tSlideShowDiv

  
end dottedSlideShow
