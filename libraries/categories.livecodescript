script "categories"

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
        rigLogMessage "debug", "Categories Library Loaded"
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
-- rigLogMessage "debug", "Categories Library Loaded" ------------ rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialCategoriesConfig pConfig
    # Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialCategoriesConfig

# Brahmanathaswami: 2016-03-26
# based on tree built in Excell with the help of Vayudeva

# Columns in table "category_tree
--category_tree_id: auto_incremented (nothing to do)
--parent_id: of the category
--child_id: of the category

# command uploadCategoryTree
# put url "file:/home/devhap/public_html/media/apps/sivasiva/finalTreeUpload.txt" into tInputData

# 	repeat for each line x of tInputData
# 		if x contains "root" then
# 			next repeat # skip it; no records to enter
# 		else

# 			put item 1 of line x into tChildCategoryID
# 			# check col 3 for a parent and insert	
# 			put item 3 of line x into tFirstParentID
# 				if item tFirstParentID <> empty then
# 					put tFirstParentID into tData["parent_id"]
# 					put tChildCategoryID into tData["child_id"]
# 					get rigDbInsert("category_tree", tData)		
# 				end if
# 				# check col 5 for a second parent and insert	
# 			put item 5 of line x into tSecondParentID
# 			if tSecondParentID <> empty then
# 				put tSecondParentID into tData["parent_id"]
# 				put tChildCategoryID into tData["child_id"]
# 				get rigDbInsert("category_tree", tData)		
# 			end if
# 		end if
# 	end repeat

# end uploadCategoryTree

command fetchCategories

    # We need data for the Category Picker Widget in HAPMAN
	# One set from the category table 
	# One set from the category_tree
	# return as simple tab delimited with | between two sets
	# we will do the work on the client side
	
	get rigDbGet("category")
	put rigDBresult() into tResult
	
	repeat for each key tKey in tResult
		put tResult[tKey] into tRow
		put tRow[2] & tab after tResultData
		put tRow[1] & cr after tResultData
	end repeat
	
	put "|" & cr after tResultData
	
	get rigDbGet("category_tree")
	put rigDBresult() into tTreeResult
	
	repeat for each key tKey in tTreeResult
		put tTreeResult[tKey] into tTreeRow
		put tTreeRow[2] & tab after tResultData
		put tTreeRow[3] & cr after tResultData
	end repeat
	
	put tResultData
end fetchCategories

	


