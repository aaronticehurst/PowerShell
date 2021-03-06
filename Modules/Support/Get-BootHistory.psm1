Function Get-BootHistory {
    #requires -version 2


    <#
     .SYNOPSIS
          Check the boot history of a computer.
     .DESCRIPTION
          This is used to check the boot history of a computer. 
     .PARAMETER  ComputerName
          The Computer that you are targeting.
     .EXAMPLE
	 	  PS C:\Scripts\> Get-BootHistory -ComputerName COMPUTERNAME

		  Scans eventlogs for the boot history.
	 .EXAMPLE
	 	  PS C:\Scripts\> Get-BootHistory -ComputerName COMPUTERNAME | select -first 3

		  Scans eventlogs for the boot history and returns the first 3 results.		 
	 .NOTES
          Written by Aaron Ticehurst on 3/2/2010. 
		  Last modification: 27/3/2011.
		  		 	  
#>

    #Written by Aaron Ticehurst 



    param(
        [CmdletBinding()]
        [parameter(Mandatory=$true,
            ValueFromPipeline= $true)]
        [string]$ComputerName
    )	
			
			
    Function Get-BootHistory {
					
        $GetBoot = Get-Eventlog -ComputerName $ComputerName -logname system | Where-Object {$_.EventID -eq 6009}
        Write-Host -foregroundcolor yellow "The computer"$ComputerName "has been booted up at the following times:"
        Write-Host
        foreach ($item in $GetBoot) {
				        Write-Output $item.timeGenerated
        }
    }
				

    #Test to see if script is able to connect to the requested computer.
    $Test = Test-Connection -computername $ComputerName -quiet -count 1

    If ($ComputerName -eq "."){
        Get-BootHistory
    }
    Elseif  ($Test -eq "True"){
        Get-BootHistory
    }
    Else {
        Write-host "Unable to connect to the requested computer."
    }

}

New-Alias -name GBH -value Get-BootHistory
Export-ModuleMember Get-BootHistory -Alias GBH