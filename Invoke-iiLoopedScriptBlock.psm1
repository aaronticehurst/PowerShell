Function Invoke-iiLoopedScriptBlock {

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
                  PS C:\> Invoke-iiLoopedCommand { Resolve-DnsName sma.staff.iinet.net.au} -Loops 100 -SecondsSleep 10
          Check diskspace of isp-osb-dfs1
     .NOTES
          Written by Aaron Ticehurst 24/5/2016.
#>


param([CmdletBinding()]

  [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipelineByProperty=$true,
                    Position=0)]                    
	                [scriptblock]$Scriptblock,
        [Parameter(Mandatory=$False,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipelineByProperty=$true,
                    Position=1)]
                    [INT]$Loops=10,
        [Parameter(Mandatory=$False,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromPipelineByProperty=$true,
                    Position=2)]
        [INT]$SecondsSleep = 60
 )

         for ($i = 1; $i -le $Loops; $i++)
        { 
                    $Scriptblock.Invoke()
                    Start-Sleep -Seconds $SecondsSleep
        }

}

Export-ModuleMember Invoke-iiLoopedScriptBlock
