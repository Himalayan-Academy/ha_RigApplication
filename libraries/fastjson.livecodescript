script "fastjson"

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
        rigLogMessage "debug", "FastJSON Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ----------------------- currently not needed ------ rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialfastjsonConfig pConfig

end rigRunInitialfastjsonConfig




-- rigLogMessage "debug", "FastJSON Library Loaded" -------------------- rabit


# DECLARE SCRIPT LOCAL VARIABLES

local sOutputUTF8
local sIndexJSON
local sNumTokensJsonData
local sJsonData

##
# -------------------------------------------------------------------
#  JSON to Array
# -------------------------------------------------------------------
# Convert a valid JSON data structure to a multi-dimensional Livecode
# array.
#
# Prototype:
#
#     put jsonToArray( tJsonData, false, true ) into tArrayData
#
##
function jsonToArray @pJson, asUnicode, pSkipValidation
   put asUnicode is true into sOutputUTF8
   put jsonToUtf8(pJson) into tJson

   if tJson begins with "fastJson-error" then return tJson

   if pSkipValidation then
      tokenize tJson
   else
      if not isJsonData(tJson) then -- isJsonData will tokenize tJson for us
         return false
         //else
         //tokenize tJson
      end if
   end if

   //if the result is not empty then return the result
   put 0 into sIndexJSON
   put jObjectToArray() into tArray
   put empty into sJsonData
   return tArray
end jsonToArray

##
#
#  Included for compatibility with easyJson scripts
#
##
function arrayFromJson @pJson
   return jsonToArray(pJson)
end arrayFromJson

##
# -------------------------------------------------------------------
#  Array To JSON
# -------------------------------------------------------------------
# Convert a multi-dimensional Livecode array to a valid JSON data
# structure.
#
# Prototype:
#
#     put arrayToJson( tArrayData ) into tJsonData
#
##
function arrayToJson @pArray keepNumeric
   if pArray is not an array then return "Parser Error: parameter given is not an array."
   local tJSON
   if isNumericalArray(pArray) and keepNumeric is not true then
      # the array's keys are all *numerical*, so the root element will be a JSON *array*
      # if keepNumeric is true, then the keys will remain numeric keys
      put "[" into tJSON
      local tValue
      repeat for each element tValue in pArray
         put jsonValue(tValue) & comma after tJSON
      end repeat
      put "]" into the last char of tJSON
   else
      # the array's keys are not all numerical, so the root element will be a JSON *object*
      put "{" into tJSON
      local tKey
      repeat for each key tKey in pArray
         # all JSON object keys are double-quoted strings:
         put quote & tKey & quote & ":" & jsonValue(pArray[tKey]) & comma after tJSON
      end repeat
      put "}" into the last char of tJSON
   end if
   return tJSON
end arrayToJson

##
#
#  Included for compatibility with easyJson scripts
#
##
function jsonFromArray @pJson
   return arrayToJson(pJson)
end jsonFromArray

##
# -------------------------------------------------------------------
#  Validate JSON data structure
# -------------------------------------------------------------------
# Validates a JSON data structure
#
#
# Prototype:
#
#     if isJsonData( tJsonData ) then
#        put "Valid JSON" into tTemp
#     else
#        put "ERROR! Not Valid JSON"
#     end if
#
##
function isJsonData @pJson

   tokenize pJson

   repeat for each element tToken in sJsonData
      if tToken is in "{[" then add 1 to tDepth
      if tToken is in "}]" then subtract 1 from tDepth
   end repeat

   if tDepth <> 0 then return false

   put 2 into n
   repeat for each element tToken in sJsonData
      --repeat with n = 1 to sNumTokensJsonData - 1
      if (sJsonData[n-1] is not in "{}[],:") and (sJsonData[n] is not in "{}[],:") then return false
      add 1 to n
   end repeat

   return true
end isJsonData

/*
This was the original tokeninze code from libJson commented out for now.
This code will be removed eventually.

Bob Hall (2015-OCT-02)

private command tokenizeJson pJson
   put empty into sJsonData
   put 0 into sIndexJSON
   put 0 into sNumTokensJsonData

   # escaped quotes < \" > and reverse-solidus < \\ > will confuse the tokenizer
   # so we replace them with "\u0022" and "\u005C" which we'll unescape
   # with all the other unescapes when we parse - jsonDecode()
   replace "\\" with "\u005C" in pJson
   replace "\" & quote with "\u0022" in pJson

   put 0 into tDepth
   put empty into prevToken
   repeat for each token tToken in pJson
      if tToken is in "+-" then
         # since "+" & "-" are rev tokens, but not jSon tokens,
         # we have to prepend them to the next token
         put tToken into prevToken
      else
         add 1 to sNumTokensJsonData
         put prevToken & tToken into sJsonData[sNumTokensJsonData]
         put empty into prevToken

         if tToken is in "{[" then add 1 to tDepth
         if tToken is in "}]" then subtract 1 from tDepth
      end if
   end repeat

   if tDepth <> 0 then return "fastJson-error: json malformed"
   repeat with n = 1 to sNumTokensJsonData - 1
      if (sJsonData[n] is not in "{}[],:") and (sJsonData[n + 1] is not in "{}[],:") then return "fastJson-error: json malformed"
   end repeat
end tokenizeJson
*/

private function jObjectToArray
   put empty into tArray

   -- using a repeat forever with a conditional got small improvement
   repeat forever
      --repeat while sIndexJSON <= sNumTokensJsonData
      if sIndexJSON > sNumTokensJsonData then exit repeat
      add 1 to sIndexJSON

      switch sJsonData[sIndexJSON]
         case "{"
            put jsonDecode(sJsonData[sIndexJSON + 1]) into tName
            add 1 to sIndexJSON -- we can skip ahead
            break
         case ":"
            if sJsonData[sIndexJSON + 1] is not "{" then
               put jsonDecode(sJsonData[sIndexJSON + 1]) into tArray[tName]
            else
               put jObjectToArray() into tArray[tName]
            end if
            break
         case "}"
            return tArray
            break
         case "["
            put jArrayToArray() into tArray[tName]
            break
         case comma -- must be after "[" or will mess up jArrays
            put jsonDecode(sJsonData[sIndexJSON + 1]) into tName
            add 1 to sIndexJSON -- we can skip ahead
            break
      end switch

   end repeat
   return tArray
end jObjectToArray

private function jArrayToArray
   put 0 into tKey
   put empty into tArray

   repeat while sIndexJSON <= sNumTokensJsonData
      add 1 to sIndexJSON

      switch sJsonData[sIndexJSON]
         case "]"
            return tArray
            break
         case comma
            next repeat
            break
         case "{"
            add 1 to tKey
            subtract 1 from sIndexJSON
            put jObjectToArray() into tArray[tKey]
            break
         case "["
            add 1 to tKey
            put jArrayToArray() into tArray[tKey]
            break
         default
            add 1 to tKey
            put jsonDecode(sJsonData[sIndexJSON]) into tArray[tKey]
      end switch
   end repeat
end jArrayToArray

private function jsonToUtf8 @pJson
   local tNulls = "1111"

   ##
   # Repeat for each is faster than repeat with
   #
   put "1,2,3,4" into tCounter
   repeat for each element n in tCounter
      --repeat with n = 1 to 4
      if (byte n of pJson is null) then put 0 into char n of tNulls
   end repeat

   put (char 1 of (binaryencode("I",1)) is null) into bigEndian

   switch tNulls
      case "1111"  -- UTF-8
         return pJson
         break
      case "0101"  -- UTF-16BE
         if bigEndian then
            return utf8encode(pJson, true)
         else
            return utf8encode(swapEndianness(pJson), true)
         end if
         break
      case "1010"  -- UTF-16LE
         if not bigEndian then
            return utf8encode(pJson, true)
         else
            return utf8encode(swapEndianness(pJson), true)
         end if
         break
      case "0001"  -- UTF-32BE
         return "fastJson-error: 4 byte unicode, can't decode"
         break
      case "1000"  -- UTF-32LE
         return "fastJson-error: 4 byte unicode, can't decode"
         break
   end switch
end jsonToUtf8

private function utf8encode pString, pIsUnicode
   if pIsUnicode then
      return unidecode(pString, "UTF8")
   else
      return unidecode(uniencode(pString),"UTF8")
   end if
end utf8encode

private function utf8decode pString, pToUnicode
   if pToUnicode then
      return uniencode(pString,"UTF8")
   else
      return unidecode(uniencode(pString,"UTF8"))
   end if
end utf8decode

private function jsonDecode pString
   switch pString
      case "false"
         return "false"
         break
      case "true"
         return "true"
         break
      case "null"
         return empty
         break
      default
         if pString is a number then
            return pString
         else
            replace "\" & quote with quote in pString
            replace "\\" with "\" in pString
            replace "\b" with numtochar(8) in pString
            replace "\t" with numtochar(9) in pString
            replace "\f" with numtochar(12) in pString
            replace "\r" with numtochar(13) in pString
            replace "\n" with numtochar(10) in pString

            -- some more common unicode escapees
            replace "\u0022" with quote in pString
            replace "\u005C" with "\" in pString
            -- any others

            ##
            # REMOVED 10/15/2015 by BobH
            # Below causing issues with RTF escaped characters.
            # In general I am removing Unicode support for the time being.
            #
            ## if "\u" is in pString then put unicodeEscapes(pString) into pString

            ##
            # JSON encoders escape unicode characters as "\uHHHH",
            # where 'H' is a hexadecimal digit. Convert to UTF8
            #
            repeat while matchtext(pString,"\\u([0-9A-Fa-f]{4})",tCode)
               set the useunicode to true
               put unidecode(numtochar(baseconvert(tCode,16,10)),"UTF8") into tChar
               replace ("\u" & tCode) with tChar in pString
            end repeat

            if not sOutputUTF8 then
               return utf8decode(pString)
            else
               return pString
            end if
         end if
   end switch
end jsonDecode

##
# REMOVED 10/16/2015 by BobH
# Removed this function. Replaced with code in Json string hanlding
#
/*
private function unicodeEscapes pString
   put false into inEsc
   repeat for each char c in pString
      add 1 to count
      put c after buffer

      if count < 2 then next repeat

      if buffer is "\u" then put true into inEscape

      if inEscape then
         if length(buffer) < 6 then
            next repeat
         else
            put numtochar(baseconvert(char 3 to 6 of buffer, 16, 10)) into buffer
            put false into inEscape
         end if
      else
         put char 1 of buffer after nString
         delete char 1 of buffer
      end if

   end repeat
   put buffer after nString
   return nString
end unicodeEscapes
*/

/*
This function checks the keys of a LiveCode array,
and returns TRUE if all the keys are numerical - otherwise, returns false.

@param pArray a LiveCode array
@return TRUE if the array's keys are all numerical, otherwise FALSE
*/
private function isNumericalArray pArray
   local tKeys
   put the keys of pArray into tKeys
   /*
   filter tKeys without "^[0-9]+$"
   if the number of lines in tKeys > 0 then 
        return false
   else
        return true
    end if
   */
   
   repeat for each line tK in tKeys
       if tK is not a number then
           return false
       end if
   end repeat
   return true
end isNumericalArray

/*
This function takes a LiveCode value, and produces a string representing
a valid JSON 'value', as per http://www.json.org/.
@param pValue any LiveCode value: array, string, number, date, colour, boolean, etc.
@return a string representing a valid and comparable JSON 'value' - JSON values are:
        number, string, boolean, array or object.
        LiveCode 'empty' returns JSON 'null'.
*/
private function jsonValue pValue
   switch
      case pValue is an array
         # this allows us to have nested JSON objects and arrays:
         return arrayToJson(pValue)
         break
      case pValue is empty
         return "null"
         break
      case pValue is a boolean
         if pValue then return "true"
         else return "false"
         break
      case pValue is a number
         -- need to catch when a "number" starts with a 0
         -- decided to return this as a quoted string
         -- JSON lint throws an exception if a number starts with a 0
         if (character 1 of pValue = 0) and not (character 2 of pValue = ".") and (length(pValue) > 1) then
            return quote & pValue & quote
         end if
         -- there is an "anomoly" in LC where "inf" and "Infinity" are getting through "is a number"
         -- function. Not sure what the result will be but the code below will catch both.
         -- I have submitted the following bugs: 16160, 16162, 16163
         if char 1 of pValue is "i" then
            return quote & pValue & quote
         else
            return pValue
         end if
      default
         # any other value is processed as a string.
         # JSON strings require that certain characters be 'escaped' with a backslash:
         replace "\" with "\\" in pValue // the backslash itself
         replace quote with ("\" & quote) in pValue // the double quote
         replace "/" with "\/" in pValue // the (forward) slash
         replace tab with "\t" in pValue // the tab
         replace return with "\n" in pValue // the return
         replace cr with "\n" in pValue // the return
         replace lf with "\n" in pValue // the return
         replace crlf with "\n" in pValue // the return
         replace newline with "\n" in pValue // the return         
         return quote & pValue & quote
   end switch
end jsonValue

private command tokenize @pJson
   put "" into sJsonData
   put 0 into sNumTokensJsonData

   # escaped quotes < \" > and reverse-solidus < \\ > will confuse the tokenizer
   # so we replace them with "\u0022" and "\u005C" which we'll unescape
   # with all the other unescapes when we parse - jsonDecode()
   replace "\\" with "\u005C" in pJson
   replace "\" & quote with "\u0022" in pJson

   put 1 into sIndexJSON
   put "" into prevToken
   repeat for each token tToken in pJson
      if tToken is in "+-" then -- needed for numbers in json
         # since "+" & "-" are rev tokens, but not jSon tokens,
         # we have to prepend them to the next token
         put tToken into prevToken
      else
         add 1 to sNumTokensJsonData
         put prevToken & tToken into sJsonData[sNumTokensJsonData]
         put "" into prevToken
      end if
   end repeat
end tokenize

function numTokens @pJson
   tokenize pJson

   return sNumTokensJsonData
end numTokens


