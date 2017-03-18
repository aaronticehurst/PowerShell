function ConvertFrom-Base64 ($String) {

    <#
     .SYNOPSIS
          Decode the corrupted ets tickets.
     .DESCRIPTION
          Decode the corrupted ets tickets.
     .EXAMPLE
	 	  C:\scripts> ConvertFrom-Base64 "Base64String"

		  Converts Base64 String into a readable format.
	 .NOTES
          Written by Aaron Ticehurst, code is actually from http://www.techmumbojumblog.com/?p=306.
		  Last modification 7/8/2011.
		  
#>


    $bytes  = [System.Convert]::FromBase64String($string);
    $decoded = [System.Text.Encoding]::UTF8.GetString($bytes); 

    return $decoded;

}

Export-ModuleMember ConvertFrom-Base64