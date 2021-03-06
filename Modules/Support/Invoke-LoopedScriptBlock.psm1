﻿Function Invoke-LoopedScriptBlock {

     <#
     .SYNOPSIS
          Loops a scriptbock
     .DESCRIPTION
            Simple looping function to loop a command block so you don't need to keep running it yourself.
     .PARAMETER  Scriptblock
          The block of code you want to loop
    .PARAMETER  Loops
          Finite number of loops to run the scriptblock
    .PARAMETER  SecondsSleep
          Number of seconds between each loop
         .EXAMPLE
                  PS C:\> Invoke-LoopedScriptBlock { Resolve-DnsName google.com.au} -Loops 100 -SecondsSleep 10
          Keeps running script or command for loop duration
     .NOTES
          Written by Aaron Ticehurst 6/12/2012.
#>


param([CmdletBinding()]

  [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true,
                    Position=0)]                    
	                [scriptblock]$Scriptblock,
        [Parameter(Mandatory=$False,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true,
                    Position=1)]
                    [INT]$Loops=10,
        [Parameter(Mandatory=$False,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipeline=$true,
                    Position=2)]
        [INT]$SecondsSleep = 60
 )

         for ($i = 1; $i -le $Loops; $i++)
        { 
                    $Scriptblock.Invoke()
                    Start-Sleep -Seconds $SecondsSleep
        }

}

Export-ModuleMember Invoke-LoopedScriptBlock