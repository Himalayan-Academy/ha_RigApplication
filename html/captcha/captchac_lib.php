<?php
// ----------------------------------------------------------------
// Captcha Creator PHP Image Displaying Script.
// Copyright (c) 2007 Alexandru Marias. All rights reserved
// Web: http://www.captchacreator.com
// Phone: +40722486348
// ----------------------------------------------------------------

 session_start();

function RandomCode($min,$max) // Chose the turing code
{
// Choosing a random Security Code
Global $CSrc;  // CSrc contains the characters from which the Captcha Code will be generated

$srclen = strlen($CSrc)-1;

// Chose the length of the turing code
$length = mt_rand($min,$max); // Between 4 and 8 chars

$Code = '';

// Fill the turing string with characters and numbers from $src
for($i=0; $i<$length; $i++) 
	$Code .= substr($CSrc, mt_rand(0, $srclen), 1);

return $Code;

}

// ----------------------------------------------------------------
function CheckCaptcha($Turing)
{ 

global $ImageCode;     

if ( session_id() == "" )
	{
	// We have no session id. There is no captcha code stored anywhere
	// Return false
	$ImageCode = 'wrong'; return 0;
	}

if ( !isset( $_SESSION['turing_string'] ) ) 
	{ 
	// We have a session id, but the Turing String is empty, it was not generated yet.
	// Return true
	$ImageCode = ''; return 1; 
	}
	else if ( strtoupper($_SESSION['turing_string']) == strtoupper($Turing) ) 
			{ 
			// Session id is ok, and Generated captcha is identical to user entered captcha
			// Return true
			$ImageCode = 'ok'; return 1; 
			}
		else { $ImageCode = 'wrong'; return 0; }
}
  


?>