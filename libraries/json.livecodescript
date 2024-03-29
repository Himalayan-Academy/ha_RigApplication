script "json"

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
        rigLogMessage "debug", "JSON Library" && json.libVersion() && "Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



------------------------------------------------------------------
------------------------------------------------------------------
/*
libJson 1.0.4b
Author: mark Smith
Date: 9th September 2009

changed:
1.0.4b
now handles diacritic chars better - thanks to Joel Guillod (imed-editions)
1.0.3b
empty array values are now properly encoded into a json object as empty <""> instead of as literal "null".

*/
------------------------------------------------------------------
------------------------------------------------------------------

local sJson
local sIndex
local sNumTokens
local sOutputUnicode = false
local sUnicodeInput = false

-----

-- rigLogMessage "debug", ("JSON Library" && json.libVersion() && "Loaded") ---- rabit

# RUN INITIAL CONFIGURATION PROCEDURES.
command rigRunInitialJsonConfig pConfig
   if pConfig is not an array then
     if pConfig is not empty then
       split pConfig using numtochar(1) and numtochar(2)
     end if
   end if

   if pConfig is an array then
   --Do something with pConfig.
   end if
end rigRunInitialJsonConfig

function json.libVersion
   return "1.0.2b"
end json.libVersion

-----
--> json to rev


function jsonToArray pJson, asUnicode
   put asUnicode is true into sOutputUnicode
   put json.toUtf8(pJson) into tJson
   if tJson begins with "libJson-error"then return tJson
   
   tokenizeJson tJson
   if the result is not empty then return the result
   
   if char 1 of pJson is "{" then
      put jObjectToArray() into tArray
   else
      put jArrayToArray() into tArray
   end if
   put empty into sJson
   return tArray
    
end jsonToArray

-----

command tokenizeJson pJson
   put empty into sJson
   put 0 into sIndex
   put 0 into sNumTokens
   
   -- escaped quotes < \" > and reverse-solidus < \\ > will confuse the tokenizer
   -- so we replace them with "\u0022" and "\u005C" which we'll unescape
   -- with all the other unescapes when we parse - json.decode()
   
   replace "\\" with "\u005C" in pJson
   replace "\" & quote with "\u0022" in pJson
   
   put 0 into tDepth
   put empty into prevToken
   repeat for each token tToken in pJson
      if tToken is in "+-" then
         -- since "+" & "-" are rev tokens, but not json tokens,
         -- we have to prepend them to the next token
         put tToken into prevToken
      else
         add 1 to sNumTokens
         put prevToken & tToken into sJson[sNumTokens]
         put empty into prevToken
          
         if tToken is in "{[" then add 1 to tDepth
         if tToken is in "}]" then subtract 1 from tDepth
         
      end if
   end repeat
   
   if tDepth <> 0 then return "libJson-error: json malformed"
   repeat with n = 1 to sNumTokens - 1
      if (sJson[n] is not in "{}[],:") and (sJson[n + 1] is not in "{}[],:") then return "libJson-error: json malformed"
   end repeat
   
end tokenizeJson

-----

function jObjectToArray
   put empty into tArray
  
   repeat while sIndex < sNumTokens
      add 1 to sIndex
      
      switch sJson[sIndex]
         case "{"
            put json.decode(sJson[sIndex + 1]) into tName
            break
         case ":"
            if sJson[sIndex + 1] is not "{" then
               put json.decode(sJson[sIndex + 1]) into tArray[tName]
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
         case comma --must be after "[" or will fuck up jArrays
            put json.decode(sJson[sIndex + 1]) into tName
            break
      end switch
      
   end repeat
   return tArray
end jObjectToArray

-----

function jArrayToArray
   put 0 into tKey
   put empty into tArray
   
   repeat while sIndex < sNumTokens
      add 1 to sIndex
      
      switch sJson[sIndex]
         case "]"
            return tArray
            break
         case comma
            next repeat
            break
         case "{"
            add 1 to tKey
            subtract 1 from sIndex
            put jObjectToArray() into tArray[tKey]
            break
         case "["
            add 1 to tKey
            put jArrayToArray() into tArray[tKey]
            break
         default
            add 1 to tKey
            put json.decode(sJson[sIndex]) into tArray[tKey]
      end switch
      
   end repeat
end jArrayToArray

------------------------------------------------------------------
------------------------------------------------------------------
--> rev to json


function arrayToJson pArray, asUnicode
   put asUnicode is true into sUnicodeInput
   
   if arrayKeysAreNumeric(pArray) then
      put arrayToJarray(pArray) into tJson
   else
      put arrayToJobject(pArray) into tJson
   end if
   
   return tJson
end arrayToJson

-----

function arrayToJobject pArray
   put "{" into tJson
   
   put keys(pArray) into tKeys
   sort lines of tKeys
   repeat for each line k in tKeys
      put q(json.encodeString(k)) & ":" after tJson
      
      if pArray[k] is an array then
          
         if arrayKeysAreNumeric(pArray[k]) then
            put arrayToJarray(pArray[k]) & comma after tJson
         else
            put arrayToJobject(pArray[k]) & comma after tJson
         end if
         
      else
          
         put json.encodeValue(pArray[k]) & comma after tJson
         
      end if
   end repeat
   
   put "}" into char -1 of tJson
   
   return tJson
end arrayToJobject

-----

function arrayToJarray pArray
   put the keys of pArray into tKeys
   sort tKeys numeric
   put "[" into tJarray
   
   repeat for each line k in tKeys
      if pArray[k] is an array then
         if arrayKeysAreNumeric(pArray[k]) then
            put arrayToJarray(pArray[k]) & comma after tJarray
         else
            put arrayToJobject(pArray[k]) & comma after tJarray
         end if
      else
         put json.encodeValue(pArray[k]) & comma after tJarray
      end if
   end repeat
   put "]" into char -1 of tJarray
   return tJarray
end arrayToJarray

-----

function arrayKeysAreNumeric pArray
   repeat for each key k in pArray
      if k is not an integer then return false
   end repeat
   return true
end arrayKeysAreNumeric

------------------------------------------------------------------
------------------------------------------------------------------

------------------------------------------------------------------
------------------------------------------------------------------
--> utilities

-- function json.format pJson, pIndentSize
   -- if pIndentSize is empty then put 3 into pIndentSize
   -- repeat pIndentSize
      -- put space after tIndent
   -- end repeat
   -- put 0 into tDepth
   -- 
   -- replace ":" with ": " in pJson
   -- replace comma with comma & cr in pJson
   -- replace "{" with "{" & cr in pJson
   -- replace "[" with "[" & cr in pJson
   -- replace "}" with "}" & cr in pJson
   -- replace "]" with "]" & cr in pJson
   -- replace "}" & cr & comma with "}," in pJson
   -- replace "]" & cr & comma with "]," in pJson
   -- 
   -- repeat for each line L in pJson
      -- repeat tDepth
         -- put tIndent after nJson
      -- end repeat
      -- put L & cr after nJson
       -- 
      -- if "{" is in L then add 1 to tDepth
      -- if "[" is in L then add 1 to tDepth
      -- if "}" is in L then subtract 1 from tDepth
      -- if "]" is in L then subtract 1 from tDepth
   -- end repeat
   -- return nJson
-- end json.format

function json.format pJson, pIndentSize
   if pIndentSize is empty then put 3 into pIndentSize
   repeat pIndentSize
      put space after tIndent
   end repeat
   put 0 into tDepth
   put false into inString
   
   put empty into prevChar
   repeat for each char c in pJson
      if c is quote and prevChar is not "\" then put not Instring into inString
      if not inString then
         switch c
            case "{"
            case "["
               put c & cr after tFormatted
               add 1 to tDepth
               break
            case ":"
               put c & space after tFormatted
               break
            case "}"
            case "]"
               put c & cr after tFormatted
               subtract 1 from tDepth
               break
            case comma
               if prevChar is in "}]" then delete line -1 of tFormatted
               put c & cr after tFormatted
               break
            default
               put c after tFormatted
               break
         end switch
      else
         put c after tFormatted
      end if
      
      put c into prevChar
      
      if char -1 of tFormatted is cr then
         repeat tDepth
            put tIndent after tFormatted
         end repeat
      end if
   end repeat
   
   return tFormatted
end json.format

-----

function json.decode pString
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
            if "\u" is in pString then put unicodeEscapes(pString) into pString
            
            if not sOutputUnicode then
               return utf8decode(pString)
            else
               return pString
            end if
         end if
   end switch
end json.decode

-----

function unicodeEscapes pString
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
            -- TO DEAL WITH DIACRITICS : 
            if platform() is "MacOS" then 
               put isotomac(numtochar(baseconvert(char 3 to 6 of buffer, 16, 10))) into buffer 
            else 
               put numtochar(baseconvert(char 3 to 6 of buffer, 16, 10)) into buffer 
            end if 
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

-----

function json.encodeValue pString
   switch pString
      case true
         return "true"
         break
      case false
         return "false"
         break
      case "null"
         return "null"
         break
      case empty
         return quote & quote
         break
      default
         if pString is not a number then
            return q(json.encodeString(pString))
         else
            return pString
         end if
         break
   end switch
end json.encodeValue

function json.encodeString pString
   replace "\" with "\\" in pString
   replace quote with "\u0022" in pString
   replace numtochar(8) with "\b" in pString
   replace numtochar(9) with "\t" in pString
   replace numtochar(10) with "\n" in pString
   replace numtochar(12) with "\f" in pString
   replace numtochar(13) with "\r" in pString
   
   repeat for each item i in "0,1,2,3,4,5,6,7,11,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31"
      replace numtochar(i) with "\u" & format("%04X", i) in pString
   end repeat
   
   -- TO DEAL WITH DIACRITICS : 
   if platform() is "MacOS" then 
      repeat with i=129 to 255 
         put numtochar(i) into c 
         put format("%04x",chartonum(mactoiso(c))) into tHexEncode 
         replace c with "\u" & tHexEncode in pString 
      end repeat 
   else 
      repeat with i=129 to 255 
         replace numtochar(i) with "\u" & format("%04x", i) in pString 
      end repeat 
   end if 
   
   if sUnicodeInput then
      return pString
   else
      return utf8encode(pString)
   end if
end json.encodeString

-----

function json.toUtf8 @pJson
   local tNulls = "1111"
   
   repeat with n = 1 to 4
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
         return "libJson-error: 4 byte unicode, can't decode"
         break
      case "1000"  -- UTF-32LE
         return "libJson-error: 4 byte unicode, can't decode"
         break
   end switch
end json.toUtf8

-----

function swapEndianness pString, pSize
   if pSize is empty then put 2 into pSize
   repeat with n = 1 to length(pString) step pSize
      repeat with s = pSize - 1 down to 0
         put byte n + s of pString  after nString
      end repeat
   end repeat
   return nString
end swapEndianness

-----

function utf8encode pString, pIsUnicode
   if pIsUnicode then
      return unidecode(pString, "UTF8")
   else
      return unidecode(uniencode(pString),"UTF8")
   end if
end utf8encode

-----

function utf8decode pString, pToUnicode
   if pToUnicode then
      return uniencode(pString,"UTF8")
   else
      return unidecode(uniencode(pString,"UTF8"))
   end if
end utf8decode

-----

/*
function q pString
   return quote & pString & quote
end q
*/

-----
