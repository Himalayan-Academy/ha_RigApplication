script "lexiconaux"

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
        rigLogMessage "debug", "Lexicon Auxiliary Library Loaded"
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
-- rigLogMessage "debug", "Lexicon Auxiliary Library Loaded" ----------- rabit

# DECLARE LOCAL VARIABLES

command rigRunInitialLexiconAuxConfig pConfig

end rigRunInitialLexiconAuxConfig

function lexiconGetDefinition pWord
	put pWord into tWordA["word"]
	rigDbWhere(tWordA)
	put rigDbGet("lexicon") into tQ
	if tQ["numrows"] is 1 then
		put rigDbRow(1) into tWordA
		delete variable tWordA["lexicon_id"]
		put tWordA["see_also"] into tSeeAlso
		put 0 into x
		repeat for each item k in tSeeAlso
			add 1 to x
			put trim(k) into tA[x]
			replace "." with empty in tA[x]
		end repeat
		put tA into tWordA["see_also"]
	else
		put "no such word" into tWordA["error"]
	end if
	return tWordA
end lexiconGetDefinition

function lexiconGetDefinitionsFromSearch pPart
	put pPart into tWord
	rigLogMessage "debug", "Lexicon searching for" & tWord
	rigDbOrderBy "word"
	rigDbLike "word", tWord
	put rigDbGet("lexicon") into tQ
	rigLogMessage "debug", "found" && tQ["numrows"] && "matches."
	if tQ["numrows"] > 0 then
		put tQ["numrows"] into tWordsA["results"]
		repeat with x = 1 to tQ["numrows"]
			put rigDbRow(x) into tWordsA["entries"][x]
			delete variable tWordsA["entries"][x]["lexicon_id"]
			put tWordsA["entries"][x]["see_also"] into tSeeAlso
			put 0 into y
			repeat for each item k in tSeeAlso
				add 1 to y
				put trim(k) into tA[y]
				replace "." with empty in tA[y]
			end repeat
			put tA into tWordsA["entries"][x]["see_also"]
		end repeat
	else
		put "no search results" into tWordsA["error"]
	end if
	rigLogMessage "debug", "last SQL:" & rigDbLastQuery()
	return tWordsA
end lexiconGetDefinitionsFromSearch

function lexiconGetDefinitionsFromAlpha pAlpha
	rigLogMessage "debug","Lexicon alpha search for"&&pAlpha
	rigDbOrderBy "word"
	rigDbLike "word", pAlpha, "after"
	put rigDbGet("lexicon") into tQ
	rigLogMessage "debug", "found" && tQ["numrows"] && "matches."
	if tQ["numrows"] > 0 then
		put tQ["numrows"] into tWordsA["results"]
		repeat with x = 1 to tQ["numrows"]
			put rigDbRow(x) into tWordsA["entries"][x]
			delete variable tWordsA["entries"][x]["lexicon_id"]
			put tWordsA["entries"][x]["see_also"] into tSeeAlso
			put 0 into y
			repeat for each item k in tSeeAlso
				add 1 to y
				put trim(k) into tA[y]
				replace "." with empty in tA[y]
			end repeat
			put tA into tWordsA["entries"][x]["see_also"]
		end repeat
	else
		put "no search results" into tWordsA["error"]
	end if
	rigLogMessage "debug", "last SQL:" & rigDbLastQuery()
	return tWordsA
end lexiconGetDefinitionsFromAlpha



command lexiconGetWordlist
	put rigDbQuery("select word from lexicon order by word") into tQ
	put rigDBresult() into tResult
	return tResult
end lexiconGetWordlist
