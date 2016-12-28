<?php

// ----------------------------------------------------------------------------
// link_counter.php 1.0
//
// Keeps track of the number of people clicking links on your webpages.
// Author: Benjamin Keen, Sept 2003 - benjaminkeen.com
//
// See readme.txt for instructions of how to use it.
// ----------------------------------------------------------------------------

// the datafile name, used to store each link count.
$datafile = 'link_counter.txt';

main();


// ----------------------------------------------------------------------------
// function:     main
// description:  program control flow. Ensures that value for either "admin" or
//               "url" is included in query string.
// ----------------------------------------------------------------------------
function main() {

	$admin        = $_GET['admin'];
  $redirect_url = $_GET['url'];

  if ($admin)        { manage_links(); }
	if ($redirect_url) { update_datafile_and_redirect($redirect_url); }
	else {
	  echo "<html><body>View the readme.txt for an explanation of how to use link_counter.php!</body></html>";
    exit();
	}
}


// ----------------------------------------------------------------------------
// function:     update_datafile_and_redirect
// parameter:    $redirect_url - the URL to redirect to
// description:  adds new new to datafile or increments existing URLs hitcount,
//               then redirects to URL specified in parameter
// ----------------------------------------------------------------------------
function update_datafile_and_redirect($redirect_url) {

  global $datafile; // grab our global
  $datafile_lines = file($datafile);

	$found = 0;
  for ($i=0; $i<count($datafile_lines); $i++) {

		// split row by ';' character delimiter
		$record = explode(";", $datafile_lines[$i]);

		if ($redirect_url != $record[0]) { continue; }

		// URL record already exists. Increment it's hitcount by 1
  	$new_count          = $record[1] + 1;
		$updated_line       = "$redirect_url;$new_count";
		$datafile_lines[$i] = $updated_line;
		$found              = 1;

		break;
	}

	if (!$found) {
	  $new_line = "$redirect_url;1\n";
		array_push($datafile_lines, $new_line);
	}

  $FILE_HANDLE = fopen($datafile, 'w');
  foreach ($datafile_lines as $line) {
    $line = trim($line) . "\n";
    fwrite($FILE_HANDLE, $line);
  }
  fclose($FILE_HANDLE);

  // last but not least, redirect user to their URL
  header("Location: $redirect_url");
  exit();

}


// ----------------------------------------------------------------------------
// function:     manage_links
// description:  Outputs an HTML table of all links, with option for removing
//               link data
// ----------------------------------------------------------------------------
function manage_links() {

  // first, erase any links that the user checked
  if ($_POST) {

    global $datafile; // grab our global
    $datafile_lines = file($datafile);

    // loop through datafile and remove all those specified links
    $new_datafile_lines = array();
    for ($i=0; $i<count($datafile_lines); $i++) {

      // if row is to be erased, skip it
      if ($_POST["$i"]) { continue; }

  		// not being erased? Add it back to datafile
      array_push($new_datafile_lines, $datafile_lines[$i]);

  	}

    $FILE_HANDLE = fopen($datafile, 'w');
    foreach ($new_datafile_lines as $line) {
      $line = trim($line) . "\n";
      fwrite($FILE_HANDLE, $line);
    }
    fclose($FILE_HANDLE);
  }

?>

<html>
<head>

<style type="text/css">

body,table,select  { font-family: verdana;
              font-size: 8pt; }
th {          font-size: 10pt;
              text-align: left; }
input {
              font-family: verdana;
              font-size: 8pt; }
input.button { border: 1px solid #999999;
               font-size: 8pt;
               color: #175B8A; }
-->
</style>

</head>

<body topmargin="0" leftmargin="0">

<div style="background-color: #D5D5D5; height: 80px; width=100%; border-bottom: 4px solid #C3C3C3;">
<table width="700" align='center' height='50' cellpadding='0' cellspacing='0'>
  <tr><td valign='bottom'>
    <font style="font-size: 14pt;">LINK COUNTER</font>&nbsp;
    <font style="font-size: 14pt; color: #666666;">1.0</font>
 </td></tr>
</table>
</div>
<br><br>

<form name="manage_links" method="post" action="link_counter.php?admin=1">

<table cellpadding="2" width="650" align='center' style="border-left: 9px solid #cccccc; border-right: 9px solid #cccccc;">
<tr>
<td height="10" bgcolor="#39516A"><font color='white'><b>URL</b></font></td>
<td height="10" width="100" bgcolor="#39516A"><font color='white'><b>HIT COUNT</b></font></td>
<td height="10" width="50" bgcolor="#39516A"><font color='white'><b>ERASE</b></font></td>

<?php

  global $datafile; // grab our global
  $datafile_lines = file($datafile);

	$odd_row_colour  = '#779EC6';
	$even_row_colour = '#ABC3DC';

  for ($i=0; $i<count($datafile_lines); $i++) {

		// split row by ';' character delimiter
		$record = explode(";", $datafile_lines[$i]);

    // determine row colour
    $colour = ($i%2) ? $even_row_colour : $odd_row_colour;

		echo "<tr><td bgcolor='$colour'><a href='$record[0]'>$record[0]</a></td>"
		   . "<td bgcolor='$colour'>$record[1]</td>"
			 . "<td bgcolor='$colour' align='center'><input name='$i' value='erase_line_$i' type='checkbox' \></td></tr>";
	}

	if ($datafile_lines) {
	  echo "<tr><td colspan='3' align='right'><input type='submit' value='ERASE' \></td></tr>";
	}

?>


<tr><td colspan="3">

<hr style="border: 1px solid #999999;">

<div align='right'> Script by:
<a href='http://www.benjaminkeen.com/'>benjaminkeen.com</a>
</div>

</td></tr>
</table>

</form>

</body>
</html>

<?php

  exit();
}

?>